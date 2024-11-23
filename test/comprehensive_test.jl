using Test
using ChromeDevToolsLite

# Import common test utilities
include("test_utils.jl")

@testset "ChromeDevToolsLite Comprehensive Tests" begin
    client = setup_test()

    @testset "Page Operations" begin
        # Test page navigation and content retrieval
        local_path = joinpath(@__DIR__, "test_pages", "error_cases.html")
        url = "file://" * local_path
        invalid_url = "file:///nonexistent.html"

        # Test goto with verbose logging and error cases
        @test goto(client, url; verbose=true) === nothing
        @test_throws Exception goto(client, invalid_url; verbose=true)

        # Test content retrieval
        html_content = content(client; verbose=true)
        @test html_content isa String
        @test contains(html_content, "<title>Error Cases Test</title>")
        @test contains(html_content, "<div id=\"content\">Error Test Content</div>")

        # Test JavaScript evaluation with different error scenarios
        @test evaluate(client, "throwError()"; verbose=true) === nothing
        @test evaluate(client, "returnUndefined()"; verbose=true) === nothing
        @test evaluate(client, "returnNull()"; verbose=true) === nothing
        @test evaluate(client, "causeReferenceError()"; verbose=true) === nothing
        @test evaluate(client, "causeSyntaxError()"; verbose=true) === nothing
        @test evaluate(client, "invalid.syntax.error"; verbose=true) === nothing

        # Test page modification and state
        @test evaluate(client, "modifyPage()"; verbose=true) == true
        modified_content = content(client; verbose=true)
        @test contains(modified_content, "<div>Modified Content</div>")

        # Test screenshot functionality with various states
        screenshot_data = screenshot(client; verbose=true)
        @test screenshot_data isa String
        @test !isempty(screenshot_data)
        @test startswith(screenshot_data, "iVBOR") # PNG base64 header

        # Test screenshot with page modifications
        @test evaluate(client, "document.body.style.background = 'red'"; verbose=true) !== nothing
        modified_screenshot = screenshot(client; verbose=true)
        @test modified_screenshot isa String
        @test modified_screenshot != screenshot_data

        # Test content after disconnection simulation
        @test evaluate(client, "window.close()"; verbose=true) === nothing
        @test content(client; verbose=true) isa String  # Should still return content or handle gracefully
    end

    @testset "Form Interactions" begin
        # Test form.html
        local_path = joinpath(@__DIR__, "test_pages", "form.html")
        url = "file://" * local_path
        goto(client, url)

        # Test input field with ElementHandle
        input = ElementHandle(client, "#name-input")
        @test type_text(input, "Test User")
        @test evaluate_handle(input, "el => el.value") == "Test User"

        # Test checkbox with ElementHandle
        checkbox = ElementHandle(client, "#agree-checkbox")
        @test check(checkbox)
        @test evaluate_handle(checkbox, "el => el.checked") == true
        @test uncheck(checkbox)
        @test evaluate_handle(checkbox, "el => el.checked") == false
    end

        # Test screenshot functionality
        screenshot_data = screenshot(client; verbose=true)
        @test screenshot_data isa String
        @test !isempty(screenshot_data)
        @test startswith(screenshot_data, "iVBOR") # PNG base64 header

        # Test screenshot with invalid state
        @test screenshot(client; verbose=true) !== nothing  # Should still work even after previous operations
    end

    @testset "Form Interactions" begin
        # Test form.html
        local_path = joinpath(@__DIR__, "test_pages", "form.html")
        url = "file://" * local_path
        goto(client, url)

        # Test input field with ElementHandle
        input = ElementHandle(client, "#name-input")
        @test type_text(input, "Test User")
        @test evaluate_handle(input, "el => el.value") == "Test User"

        # Test checkbox with ElementHandle
        checkbox = ElementHandle(client, "#agree-checkbox")
        @test check(checkbox)
        @test evaluate_handle(checkbox, "el => el.checked") == true
        @test uncheck(checkbox)
        @test evaluate_handle(checkbox, "el => el.checked") == false
    end

    @testset "Element Visibility" begin
        # Test visibility.html
        local_path = joinpath(@__DIR__, "test_pages", "multiple_elements.html")
        url = "file://" * local_path
        goto(client, url)

        # Test visible elements
        visible_el = ElementHandle(client, "#visible-element")
        @test is_visible(visible_el)

        # Test hidden elements
        hidden_el = ElementHandle(client, "#hidden-element")
        @test !is_visible(hidden_el)

        # Test elements with visibility: hidden
        invisible_el = ElementHandle(client, "#invisible-element")
        @test !is_visible(invisible_el)
    end

    @testset "Text Content" begin
        # Test text_content.html
        local_path = joinpath(@__DIR__, "test_pages", "text_content.html")
        url = "file://" * local_path
        goto(client, url)

        # Test static text content
        content = ElementHandle(client, "#content")
        @test !isempty(get_text(content))

        # Test dynamic text content
        dynamic = ElementHandle(client, "#dynamic-content")
        initial_text = get_text(dynamic)
        button = ElementHandle(client, "#update-button")
        @test click(button)
        @test get_text(dynamic) != initial_text
    end

    @testset "Radio Buttons" begin
        # Test radio_buttons.html
        local_path = joinpath(@__DIR__, "test_pages", "radio_buttons.html")
        url = "file://" * local_path
        goto(client, url)

        # Test radio button selection
        radio1 = ElementHandle(client, "#radio1")
        radio2 = ElementHandle(client, "#radio2")

        @test check(radio1)
        @test evaluate_handle(radio1, "el => el.checked") == true
        @test evaluate_handle(radio2, "el => el.checked") == false

        @test check(radio2)
        @test evaluate_handle(radio1, "el => el.checked") == false
        @test evaluate_handle(radio2, "el => el.checked") == true
    end

    @testset "Element Evaluation" begin
        # Test element_evaluate.html
        local_path = joinpath(@__DIR__, "test_pages", "element_evaluate.html")
        url = "file://" * local_path
        goto(client, url)

        # Test attribute retrieval
        element = ElementHandle(client, "#test-element")
        @test get_attribute(element, "data-test") == "test-value"
        @test get_attribute(element, "nonexistent") === nothing

        # Test complex evaluation
        @test evaluate_handle(element, """el => {
            const rect = el.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0;
        }""") == true
    end

    @testset "Form Validation" begin
        # Test form_validation.html
        local_path = joinpath(@__DIR__, "test_pages", "form_validation.html")
        url = "file://" * local_path
        goto(client, url)

        # Test required field validation
        input = ElementHandle(client, "#required-input")
        submit = ElementHandle(client, "#submit-button")

        @test click(submit)  # Should not submit with empty required field
        @test evaluate_handle(input, "el => el.validity.valid") == false

        @test type_text(input, "valid input")
        @test click(submit)
        @test evaluate_handle(input, "el => el.validity.valid") == true
    end

    @testset "Dynamic Content and Visibility" begin
        local_path = joinpath(@__DIR__, "test_pages", "dynamic_content.html")
        url = "file://" * local_path
        goto(client, url)

        # Test delayed content visibility
        delayed = ElementHandle(client, "#delayed-content")
        @test !is_visible(delayed)

        show_button = ElementHandle(client, "#show-delayed")
        @test click(show_button)

        # Wait for animation
        sleep(1.5)  # Give extra time for the delay
        @test is_visible(delayed)

        # Test dynamic content updates
        dynamic = ElementHandle(client, "#dynamic-content")
        initial_content = get_text(dynamic)

        update_button = ElementHandle(client, "#update-button")
        @test click(update_button)
        @test get_text(dynamic) != initial_content
    end

    @testset "Complex Form Interactions" begin
        local_path = joinpath(@__DIR__, "test_pages", "complex_form.html")
        url = "file://" * local_path
        goto(client, url)

        # Test username validation
        username = ElementHandle(client, "#username")
        error_msg = ElementHandle(client, "#username-error")

        @test type_text(username, "ab")  # Too short
        @test is_visible(error_msg)

        @test type_text(username, "validuser")
        @test !is_visible(error_msg)

        # Test checkboxes
        pref1 = ElementHandle(client, "#pref1")
        pref2 = ElementHandle(client, "#pref2")

        @test check(pref1)
        @test check(pref2)
        @test evaluate_handle(pref1, "el => el.checked") == true
        @test evaluate_handle(pref2, "el => el.checked") == true

        # Test select dropdown
        select = ElementHandle(client, "#notification-type")
        @test select_option(select, "weekly")
        @test evaluate_handle(select, "el => el.value") == "weekly"

        # Test form submission
        submit = ElementHandle(client, "#submit-form")
        result = ElementHandle(client, "#form-result")

        @test click(submit)
        @test is_visible(result)
    end

    @testset "Navigation Operations" begin
        # Test navigation.html
        local_path = joinpath(@__DIR__, "test_pages", "navigation.html")
        url = "file://" * local_path
        @test goto(client, url) === nothing

        # Test navigation state
        nav_state = evaluate(client, "getNavigationState()")
        @test nav_state isa Dict
        @test haskey(nav_state, "href")
        @test haskey(nav_state, "pathname")

        # Test navigation through button click
        button = ElementHandle(client, "#redirect-button")
        @test click(button)
        sleep(0.5)  # Wait for navigation

        # Verify navigation occurred
        new_content = content(client)
        @test contains(new_content, "<title>Page Operations Test</title>")

        # Test navigation error handling
        @test evaluate(client, "triggerNavigationError()") == true
        sleep(0.5)  # Wait for attempted navigation

        # Verify we're still on a valid page
        @test !isempty(content(client))
    end

    teardown_test(client)
end

        @test click(submit)
        @test is_visible(result)
    end

    teardown_test(client)
end
