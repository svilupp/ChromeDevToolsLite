using Test
using ChromeDevToolsLite
using TestUtils

@testset "Page Base methods" begin
    # Setup mock browser and context
    mock_ws = MockWebSocket()
    browser = Browser(mock_ws, BrowserContext[], Dict{String,Any}())
    context = BrowserContext(browser, Page[], Dict{String,Any}(), "test-context-1")

    # Create test page
    page = Page(
        context,
        "page-1",
        "target-1",
        Dict{String,Any}()
    )

    # Test show method
    @test sprint(show, page) == "Page(id=page-1)"

    # Test navigation
    @testset "Page navigation" begin
        url = "https://example.com"
        goto(page, url)

        # Verify CDP message was sent correctly
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "Page.navigate"
        @test last_msg["params"]["url"] == url
    end

    # Test JavaScript evaluation
    @testset "Page evaluation" begin
        result = evaluate(page, "2 + 2")
        @test result == 4

        # Test complex evaluation
        json_result = evaluate(page, "({key: 'value'})")
        @test json_result isa Dict
        @test json_result["key"] == "value"

        # Verify CDP messages
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "Runtime.evaluate"
        @test last_msg["params"]["returnByValue"] == true
    end

    # Test page closure
    @testset "Page closure" begin
        close(page)
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "Target.closeTarget"
        @test last_msg["params"]["targetId"] == page.target_id
        @test page ∉ context.pages
    end

    @testset "Page selectors" begin
        # Test wait_for_selector with successful case
        element = wait_for_selector(page, "#test-element", timeout=1000)
        @test element isa ElementHandle
        @test element.node_id > 0
        @test element.selector == "#test-element"

        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.querySelector"
        @test last_msg["params"]["selector"] == "#test-element"

        # Test wait_for_selector with timeout
        @test_throws TimeoutError wait_for_selector(page, "#non-existent", timeout=100)

        # Test query_selector
        element = query_selector(page, ".single-element")
        @test element isa ElementHandle
        @test element.selector == ".single-element"

        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.querySelector"
        @test last_msg["params"]["selector"] == ".single-element"

        # Test query_selector_all
        elements = query_selector_all(page, ".multiple-elements")
        @test elements isa Vector{ElementHandle}
        @test length(elements) > 0
        @test all(e -> e.selector == ".multiple-elements", elements)

        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.querySelectorAll"
        @test last_msg["params"]["selector"] == ".multiple-elements"
    end

    @testset "Page interactions" begin
        # Test click
        click(page, "#click-button")
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.click"
        @test haskey(last_msg["params"], "nodeId")
        @test last_msg["params"]["clickCount"] == 1

        # Test click with options
        click(page, "#double-click", Dict("clickCount" => 2))
        last_msg = get_last_message(mock_ws)
        @test last_msg["params"]["clickCount"] == 2

        # Test type_text
        type_text(page, "#input-field", "Hello, World!")

        # Verify focus message
        focus_msg = get_last_message(mock_ws, -2)  # Get second to last message
        @test focus_msg["method"] == "DOM.focus"
        @test haskey(focus_msg["params"], "nodeId")

        # Verify type message
        type_msg = get_last_message(mock_ws)
        @test type_msg["method"] == "Input.insertText"
        @test type_msg["params"]["text"] == "Hello, World!"
        @test type_msg["params"]["type"] == "keyDown"
    end

    @testset "Page content retrieval" begin
        # Test screenshot
        screenshot_data = screenshot(page)
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "Page.captureScreenshot"
        @test last_msg["params"]["format"] == "png"
        @test last_msg["params"]["quality"] == 100
        @test last_msg["params"]["fromSurface"] == true

        # Test screenshot with options
        screenshot_data = screenshot(page, Dict("format" => "jpeg", "quality" => 80))
        last_msg = get_last_message(mock_ws)
        @test last_msg["params"]["format"] == "jpeg"
        @test last_msg["params"]["quality"] == 80

        # Test content retrieval
        html_content = content(page)

        # Verify getDocument call
        doc_msg = get_last_message(mock_ws, -2)
        @test doc_msg["method"] == "DOM.getDocument"

        # Verify getOuterHTML call
        html_msg = get_last_message(mock_ws)
        @test html_msg["method"] == "DOM.getOuterHTML"
        @test haskey(html_msg["params"], "nodeId")
    end
end

        # Test type_text
        type_text(page, "#input-field", "Hello, World!")

        # Verify focus message
        focus_msg = get_last_message(mock_ws, -2)  # Get second to last message
        @test focus_msg["method"] == "DOM.focus"
        @test haskey(focus_msg["params"], "nodeId")

        # Verify type message
        type_msg = get_last_message(mock_ws)
        @test type_msg["method"] == "Input.insertText"
        @test type_msg["params"]["text"] == "Hello, World!"
        @test type_msg["params"]["type"] == "keyDown"
    end
end
