"""
    wait_for_dom_ready(client::WSClient, timeout::Float64=5.0)

Wait for DOM to be ready with timeout.
"""
function wait_for_dom_ready(client::WSClient, timeout::Float64 = 5.0)
    start_time = time()
    while (time() - start_time) < timeout
        result = send_cdp_message(client,
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
function verify_element_exists(client, selector)
    @debug "Verifying element existence" selector
    result = send_cdp_message(client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => "!!document.querySelector('$(selector)')",
            "returnByValue" => true
        ))
    exists = get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
    @debug "Element existence check result" selector exists
    exists
end

@testset "Element Interactions" begin
    client = connect_browser(ENDPOINT)

    # Enable required domains
    send_cdp_message(client, "DOM.enable", Dict{String, Any}())
    send_cdp_message(client, "Page.enable", Dict{String, Any}())
    send_cdp_message(client, "Runtime.enable", Dict{String, Any}())

    # Initialize blank page with verification
    @info "Navigating to blank page"
    send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "about:blank"))
    @test wait_for_dom_ready(client)

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

    @info "Injecting test content"
    result = send_cdp_message(client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                document.documentElement.innerHTML = `$(html_content)`;
                console.log('Page content set');
                document.readyState === 'complete'
            """,
            "returnByValue" => true
        ))

    @test get(get(get(result, "result", Dict()), "result", Dict()), "value", false) ===
          true

    # Verify DOM readiness
    sleep(1)
    @info "Verifying DOM elements"
    selectors = ["#clickme", "#textinput", "#checkbox",
        "#dropdown", "#visible", "#hidden", "#withattr"]
    for selector in selectors
        @test verify_element_exists(client, selector)
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
        @test evaluate_handle(elements["button"], "!!el") === true
        @test evaluate_handle(elements["input"], "!!el") === true

        @test click(elements["button"])
        @test type_text(elements["input"], "Hello World")
        @test evaluate_handle(elements["input"], "el.value") == "Hello World"
    end

    @testset "Checkbox Operations" begin
        @test !evaluate_handle(elements["checkbox"], "el.checked")
        @test check(elements["checkbox"])
        @test evaluate_handle(elements["checkbox"], "el.checked")
        @test uncheck(elements["checkbox"])
        @test !evaluate_handle(elements["checkbox"], "el.checked")
    end

    @testset "Select Operations" begin
        @test select_option(elements["dropdown"], "2")
        @test evaluate_handle(elements["dropdown"], "el.value") == "2"
    end

    @testset "Visibility Tests" begin
        @test is_visible(elements["visible_div"])
        @test !is_visible(elements["hidden_div"])
    end

    @testset "Text and Attribute Operations" begin
        @info "Testing text and attribute operations"
        @test get_text(elements["visible_div"]) == "Visible Text"
        @test get_attribute(elements["attr_div"], "data-test") == "testvalue"
        @test get_attribute(elements["attr_div"], "nonexistent") === nothing
        @test evaluate_handle(elements["visible_div"], "el.textContent.trim()") ==
              "Visible Text"
    end
end
