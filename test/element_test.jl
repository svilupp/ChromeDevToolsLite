@testset "Element Interactions" begin
    client = connect_browser(ENDPOINT)

    @info "Navigating to blank page"
    send_cdp(client, "Page.navigate", Dict{String, Any}("url" => "about:blank"))
    wait_for_ready_state(client; timeout = 10.0)  # Increased timeout

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

    # Inject content
    @info "Injecting test content"
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

    # Verify DOM readiness with increased timeout
    sleep(2)  # Increased initial wait
    @info "Verifying DOM elements"
    selectors = ["#clickme", "#textinput", "#checkbox",
        "#dropdown", "#visible", "#hidden", "#withattr"]
    for selector in selectors
        @test query_selector(client, selector) !== nothing
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
        sleep(0.5)  # Wait for click to register
        @test type_text(elements["input"], "Hello World")
        sleep(0.5)  # Wait for text input
        @test evaluate_handle(elements["input"], "el.value") == "Hello World"
    end

    @testset "Checkbox Operations" begin
        @test !evaluate_handle(elements["checkbox"], "el.checked")
        @test check(elements["checkbox"])
        sleep(0.5)  # Wait for state change
        @test evaluate_handle(elements["checkbox"], "el.checked")
        @test uncheck(elements["checkbox"])
        sleep(0.5)  # Wait for state change
        @test !evaluate_handle(elements["checkbox"], "el.checked")
    end

    @testset "Select Operations" begin
        @test select_option(elements["dropdown"], "2")
        @test evaluate_handle(elements["dropdown"], "el.value") == "2"
    end

    @testset "Visibility Tests" begin
        @test is_visible(elements["visible_div"])
        @test !is_visible(elements["hidden_div"])

        pos = get_element_position(client, "#visible")
        @test pos.x >= 0
        @test pos.y >= 0
    end

    @testset "Text and Attribute Operations" begin
        @test get_text(elements["visible_div"]) == "Visible Text"
        @test get_attribute(elements["attr_div"], "data-test") == "testvalue"
        @test get_attribute(elements["attr_div"], "nonexistent") === nothing
        @test evaluate_handle(elements["visible_div"], "el.textContent.trim()") ==
              "Visible Text"
    end
end
