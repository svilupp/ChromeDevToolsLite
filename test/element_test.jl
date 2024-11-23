using Test
using ChromeDevToolsLite
using HTTP

@testset "Element Interactions" begin
    client = connect_browser()

    # Enable required domains
    send_cdp_message(client, "DOM.enable", Dict{String, Any}())
    send_cdp_message(client, "Page.enable", Dict{String, Any}())
    send_cdp_message(client, "Runtime.enable", Dict{String, Any}())

    # Initialize blank page
    send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "about:blank"))

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

    # Inject content and verify injection
    result = send_cdp_message(client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                document.documentElement.innerHTML = `$(html_content)`;
                console.log('Page content set:', {
                    html: document.documentElement.innerHTML,
                    bodyChildCount: document.body.childNodes.length,
                    elements: {
                        clickme: !!document.querySelector('#clickme'),
                        textinput: !!document.querySelector('#textinput'),
                        checkbox: !!document.querySelector('#checkbox'),
                        dropdown: !!document.querySelector('#dropdown'),
                        visible: !!document.querySelector('#visible'),
                        hidden: !!document.querySelector('#hidden'),
                        withattr: !!document.querySelector('#withattr')
                    }
                });
                true
            """,
            "returnByValue" => true
        ))
    @test get(get(get(result, "result", Dict()), "result", Dict()), "value", false) === true

    # Add a longer wait for DOM to be ready
    sleep(2)

    # Verify each element exists and log their properties
    result = send_cdp_message(client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const elements = {
                        button: document.querySelector('#clickme'),
                        input: document.querySelector('#textinput'),
                        checkbox: document.querySelector('#checkbox'),
                        dropdown: document.querySelector('#dropdown'),
                        visible: document.querySelector('#visible'),
                        hidden: document.querySelector('#hidden'),
                        withattr: document.querySelector('#withattr')
                    };

                    const status = Object.entries(elements).reduce((acc, [key, el]) => {
                        acc[key] = el ? {
                            exists: true,
                            tagName: el.tagName,
                            isConnected: el.isConnected,
                            innerHTML: el.innerHTML
                        } : { exists: false };
                        return acc;
                    }, {});

                    console.log('Element status:', JSON.stringify(status, null, 2));
                    return status;
                })()
            """,
            "returnByValue" => true
        ))

    element_status = get(
        get(get(result, "result", Dict()), "result", Dict()), "value", Dict())
    @info "Element status check" element_status

    # Verify all elements exist
    for (key, status) in element_status
        @test get(status, "exists", false) == true
    end

    # Add a longer wait to ensure DOM is fully interactive
    sleep(1)

    # Double check DOM is ready and elements are accessible
    ready_check = send_cdp_message(client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                document.readyState === 'complete' &&
                document.querySelector('#clickme') !== null &&
                document.querySelector('#textinput') !== null
            """,
            "returnByValue" => true
        ))
    @test get(get(get(ready_check, "result", Dict()), "result", Dict()), "value", false) ===
          true

    # Create element handles directly using selectors
    button = ElementHandle(client, "#clickme")
    input = ElementHandle(client, "#textinput")
    checkbox = ElementHandle(client, "#checkbox")
    dropdown = ElementHandle(client, "#dropdown")
    visible_div = ElementHandle(client, "#visible")
    hidden_div = ElementHandle(client, "#hidden")
    attr_div = ElementHandle(client, "#withattr")

    @testset "element creation" begin
        # Verify elements exist in DOM
        @test evaluate_handle(button, "!!el") === true
        @test evaluate_handle(input, "!!el") === true
    end

    @testset "checkbox operations" begin
        # First verify checkbox exists and initial state
        @test evaluate_handle(checkbox, "!!el") === true
        initial_state = evaluate_handle(checkbox, "el.checked")
        @test initial_state === false

        @test check(checkbox)
        @test evaluate_handle(checkbox, "el.checked") === true
        @test uncheck(checkbox)
        @test evaluate_handle(checkbox, "el.checked") === false
    end

    @testset "click" begin
        @test click(button)
    end

    @testset "type_text" begin
        @test type_text(input, "Hello World")
        @test evaluate_handle(input, "el.value") == "Hello World"
    end

    @testset "checkbox operations" begin
        @test !evaluate_handle(checkbox, "el.checked")
        @test check(checkbox)
        @test evaluate_handle(checkbox, "el.checked")
        @test uncheck(checkbox)
        @test !evaluate_handle(checkbox, "el.checked")
    end

    @testset "select_option" begin
        @test select_option(dropdown, "2")
        @test evaluate_handle(dropdown, "el.value") == "2"
    end

    @testset "visibility" begin
        @test is_visible(visible_div)
        @test !is_visible(hidden_div)
    end

    @testset "get_text" begin
        @test get_text(visible_div) == "Visible Text"
    end

    @testset "get_attribute" begin
        @test get_attribute(attr_div, "data-test") == "testvalue"
        @test get_attribute(attr_div, "nonexistent") === nothing
    end

    @testset "evaluate_handle" begin
        @test evaluate_handle(visible_div, "el.textContent.trim()") == "Visible Text"
    end

    # Cleanup
    close(client)
end
