@testset "ChromeDevToolsLite Comprehensive Tests" begin
    client = connect_browser(ENDPOINT)
    @testset "Form Interactions" begin
        # Test form.html
        local_path = joinpath(@__DIR__, "test_pages", "form.html")
        url = "file://" * local_path
        goto(client, url)

        # Test input field with ElementHandle
        input = ElementHandle(client, "#name")
        @test type_text(input, "Test User")
        @test evaluate_handle(input, "el => el.value") == "Test User"

        # Test checkbox with ElementHandle
        checkbox = ElementHandle(client, "#check1")
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
end