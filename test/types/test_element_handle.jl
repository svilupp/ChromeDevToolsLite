using Test
using ChromeDevToolsLite
using TestUtils

@testset "ElementHandle Base methods" begin
    # Setup mock browser, context, and page
    mock_ws = MockWebSocket()
    browser = Browser(mock_ws, BrowserContext[], Dict{String,<:Any}())
    context = BrowserContext(browser, Page[], Dict{String,<:Any}(), "test-context-1")
    page = Page(context, "page-1", "target-1", Dict{String,<:Any}())

    # Create test element handle
    element = ElementHandle(
        page,
        "element-1",
        Dict{String,<:Any}()
    )

    # Test show method
    @test sprint(show, element) == "ElementHandle(id=element-1)"

    # Test close method
    @test close(element) === nothing

    @testset "ElementHandle interactions" begin
        # Test click
        click(element)
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.click"
        @test last_msg["params"]["nodeId"] == element.element_id
        @test last_msg["params"]["clickCount"] == 1

        # Test click with options
        click(element, Dict{String,<:Any}("clickCount" => 2))
        last_msg = get_last_message(mock_ws)
        @test last_msg["params"]["clickCount"] == 2

        # Test type_text
        type_text(element, "Hello, World!")

        # Verify focus message
        focus_msg = get_last_message(mock_ws, -2)
        @test focus_msg["method"] == "DOM.focus"
        @test focus_msg["params"]["nodeId"] == element.element_id

        # Verify type message
        type_msg = get_last_message(mock_ws)
        @test type_msg["method"] == "Input.insertText"
        @test type_msg["params"]["text"] == "Hello, World!"
        @test type_msg["params"]["type"] == "keyDown"
    end

    @testset "ElementHandle form interactions" begin
        # Test check
        check(element)

        # Verify focus and click messages
        focus_msg = get_last_message(mock_ws, -2)
        @test focus_msg["method"] == "DOM.focus"
        @test focus_msg["params"]["nodeId"] == element.element_id

        click_msg = get_last_message(mock_ws)
        @test click_msg["method"] == "DOM.click"
        @test click_msg["params"]["nodeId"] == element.element_id

        # Test uncheck
        uncheck(element)
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.click"
        @test last_msg["params"]["nodeId"] == element.element_id

        # Test select_option
        select_option(element, "option-value")
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.selectOption"
        @test last_msg["params"]["nodeId"] == element.element_id
        @test last_msg["params"]["value"] == "option-value"
    end

    @testset "ElementHandle property inspection" begin
        # Test is_visible
        @test is_visible(element) == true
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.getBoxModel"
        @test last_msg["params"]["nodeId"] == element.element_id

        # Test get_text
        text = get_text(element)
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.getOuterHTML"
        @test last_msg["params"]["nodeId"] == element.element_id

        # Test get_attribute
        attr_value = get_attribute(element, "class")
        last_msg = get_last_message(mock_ws)
        @test last_msg["method"] == "DOM.getAttribute"
        @test last_msg["params"]["nodeId"] == element.element_id
        @test last_msg["params"]["name"] == "class"
    end
end
