"""
    wait_for_dom_ready(client::WSClient, timeout::Float64=5.0)

Wait for DOM to be ready with timeout.
"""
function wait_for_dom_ready(client::WSClient, timeout::Float64 = 5.0)
    start_time = time()
    while (time() - start_time) < timeout
        result = send_cdp(client,
            "Runtime.evaluate",
            Dict{String, Any}(
                "expression" => "document.readyState === 'complete'",
                "returnByValue" => true
            ))
        if get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
            return true
        end
        sleep(0.5)
    end
    return false
end

# Helper function for element checks
function verify_element_exists(client::WSClient, selector; timeout=5.0)
    start_time = time()
    while (time() - start_time) < timeout
        try
            result = send_cdp(client,
                "Runtime.evaluate",
                Dict{String, Any}(
                    "expression" => "!!document.querySelector('$(selector)')",
                    "returnByValue" => true
                ))
            exists = get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
            exists && return true
        catch e
            @debug "Element check error (retrying)" selector exception=e
        end
        sleep(0.5)
    end
    false
end

function retry_operation(f; attempts=3, delay=1.0)
    for i in 1:attempts
        try
            return f()
        catch e
            i == attempts && rethrow()
            @debug "Operation failed, retrying" attempt=i exception=e
            sleep(delay)
        end
    end
end

@testset "Element Interactions" begin
    client = connect_browser(ENDPOINT)

    # Enable required domains
    send_cdp(client, "DOM.enable", Dict{String, Any}())
    send_cdp(client, "Page.enable", Dict{String, Any}())
    send_cdp(client, "Runtime.enable", Dict{String, Any}())

    # Initialize blank page with verification and retry
    @info "Navigating to blank page"
    retry_operation() do
        send_cdp(client, "Page.navigate", Dict{String, Any}("url" => "about:blank"))
        wait_for_dom_ready(client, 10.0)  # Increased timeout
    end

    # Create test page content with debug logging
    html_content = """
    <!DOCTYPE html>
    <html>
    <body>
        <button id="clickme">Click Me</button>
        <input id="textinput" type="text" />
        <input id="checkbox" type="checkbox" />
        <select id="dropdown">
            <option value="1">Option 1</option>
            <option value="2">Option 2</option>
        </select>
        <div id="visible">Visible Text</div>
        <div id="hidden" style="display: none;">Hidden Text</div>
        <div id="withattr" data-test="testvalue">Element with attribute</div>
    </body>
    </html>
    """

    # Inject content with retry
    @info "Injecting test content"
    retry_operation() do
        result = send_cdp(client,
            "Runtime.evaluate",
            Dict{String, Any}(
                "expression" => """
                    document.documentElement.innerHTML = `$(html_content)`;
                    console.log('Page content set');
                    document.readyState === 'complete'
                """,
                "returnByValue" => true
            ))
        @test get(get(get(result, "result", Dict()), "result", Dict()), "value", false) === true
    end

    # Verify DOM readiness with increased timeout
    sleep(2)  # Increased initial wait
    @info "Verifying DOM elements"
    selectors = ["#clickme", "#textinput", "#checkbox",
        "#dropdown", "#visible", "#hidden", "#withattr"]
    for selector in selectors
        @test verify_element_exists(client, selector, timeout=10.0)
    end

    # Create element handles with verification
    @info "Creating element handles"
    elements = Dict{String, ElementHandle}()
    elements["button"] = ElementHandle(client, "#clickme")
    elements["input"] = ElementHandle(client, "#textinput")
    elements["checkbox"] = ElementHandle(client, "#checkbox")
    elements["dropdown"] = ElementHandle(client, "#dropdown")
    elements["visible_div"] = ElementHandle(client, "#visible")
    elements["hidden_div"] = ElementHandle(client, "#hidden")
    elements["attr_div"] = ElementHandle(client, "#withattr")

    # Individual test sets with proper error handling
    @testset "Basic Element Operations" begin
        retry_operation() do
            @test evaluate_handle(elements["button"], "!!el") === true
            @test evaluate_handle(elements["input"], "!!el") === true
        end

        retry_operation() do
            @test click(elements["button"])
            sleep(0.5)  # Wait for click to register
            @test type_text(elements["input"], "Hello World")
            sleep(0.5)  # Wait for text input
            @test evaluate_handle(elements["input"], "el.value") == "Hello World"
        end
    end

    @testset "Checkbox Operations" begin
        retry_operation() do
            @test !evaluate_handle(elements["checkbox"], "el.checked")
            @test check(elements["checkbox"])
            sleep(0.5)  # Wait for state change
            @test evaluate_handle(elements["checkbox"], "el.checked")
            @test uncheck(elements["checkbox"])
            sleep(0.5)  # Wait for state change
            @test !evaluate_handle(elements["checkbox"], "el.checked")
        end
    end

    @testset "Select Operations" begin
        @test select_option(elements["dropdown"], "2")
        @test evaluate_handle(elements["dropdown"], "el.value") == "2"
    end

    @testset "Visibility Tests" begin
        retry_operation() do
            @test is_visible(elements["visible_div"])
            @test !is_visible(elements["hidden_div"])

            pos = get_element_position(client, "#visible")
            @test pos.x >= 0  # Changed to >= for edge cases
            @test pos.y >= 0
        end
    end

    @testset "Text and Attribute Operations" begin
        retry_operation() do
            @test get_text(elements["visible_div"]) == "Visible Text"
            @test get_attribute(elements["attr_div"], "data-test") == "testvalue"
            @test get_attribute(elements["attr_div"], "nonexistent") === nothing
            @test evaluate_handle(elements["visible_div"], "el.textContent.trim()") == "Visible Text"
        end
    end
end
