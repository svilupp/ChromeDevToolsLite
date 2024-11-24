@testset "ChromeDevToolsLite Comprehensive Tests" begin
    client = connect_browser(ENDPOINT)

    @testset "Page Operations" begin
        # Test page navigation and content retrieval
        local_path = joinpath(@__DIR__, "test_pages", "error_cases.html")
        url = "file://" * local_path
        invalid_url = "file:///nonexistent.html"

        # Test goto with verbose logging and error cases
        @test goto(client, url; verbose = true) === nothing
        ## cannot detect
        # @test_throws Exception goto(client, invalid_url; verbose = true)

        # Test content retrieval
        html_content = content(client; verbose = true)
        @test html_content isa String
        @test occursin("<title>Error Cases Test</title>", html_content)
        @test occursin("<div id=\"content\">Error Test Content</div>", html_content)

        # Test JavaScript evaluation with different error scenarios
        e = evaluate(client, "throwError()"; verbose = true)
        @test e isa Dict
        @test e["className"] == "Error"
        @test occursin("throwError", e["description"])
        e = evaluate(client, "returnUndefined()"; verbose = true)
        @test e isa Dict
        @test e["type"] == "undefined"
        e = evaluate(client, "returnNull()"; verbose = true)
        @test e isa Dict
        e = evaluate(client, "causeReferenceError()"; verbose = true)
        @test e isa Dict
        @test e["className"] == "ReferenceError"
        @test occursin("ReferenceError", e["description"])
        e = evaluate(client, "causeSyntaxError()"; verbose = true)
        @test e isa Dict
        @test e["className"] == "SyntaxError"
        @test occursin("SyntaxError", e["description"])
        e = evaluate(client, "invalid.syntax.error"; verbose = true)
        @test e isa Dict
        @test e["className"] == "ReferenceError"
        @test occursin("ReferenceError", e["description"])

        # Test page modification and state
        @test evaluate(client, "modifyPage()"; verbose = true) == true
        modified_content = content(client; verbose = true)
        @test occursin("<div>Modified Content</div>", modified_content)

        # Test screenshot functionality with various states
        screenshot_data = screenshot(client; verbose = true)
        @test screenshot_data isa String
        @test !isempty(screenshot_data)
        @test startswith(screenshot_data, "iVBOR") # PNG base64 header

        # Test screenshot with page modifications
        @test evaluate(client, "document.body.style.background = 'red'"; verbose = true) !==
              nothing
        modified_screenshot = screenshot(client; verbose = true)
        @test modified_screenshot isa String
        @test modified_screenshot != screenshot_data

        # Test disconnection simulation
        evaluate(client, "window.close()"; verbose = true) ## works only for windows opened by the script, security
        # Test content after disconnection simulation
        @test content(client; verbose = true) isa String  # Should still return content or handle gracefully
    end

    @testset "Form Interactions" begin
        # Test form.html
        local_path = joinpath(@__DIR__, "test_pages", "form.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test input field with ElementHandle
        input = wait_for_visible(ElementHandle(client, "#name"))
        @test type_text(input, "Test User")
        sleep(0.5)  # Allow for input processing
        @test evaluate_handle(input, "el.value") == "Test User"

        # Test checkbox with ElementHandle
        checkbox = wait_for_visible(ElementHandle(client, "#check1"))
        @test check(checkbox)
        sleep(0.5)  # Allow for state change
        @test evaluate_handle(checkbox, "el.checked") == true
        @test uncheck(checkbox)
        sleep(0.5)  # Allow for state change
        @test evaluate_handle(checkbox, "el.checked") == false
    end

    @testset "Element Visibility" begin
        # Test visibility.html
        local_path = joinpath(@__DIR__, "test_pages", "multiple_elements.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test visible elements
        visible_el = wait_for_visible(ElementHandle(client, "[data-testid='item1']"))
        @test is_visible(visible_el)

        # Test hidden elements (using display: none)
        hidden_el = ElementHandle(client, "[data-testid='item3']")
        @test !is_visible(hidden_el)

        # Test special element
        special_el = wait_for_visible(ElementHandle(client, "[data-testid='item5']"))
        @test is_visible(special_el)
    end

    @testset "Text Content" begin
        # Test text_content.html
        local_path = joinpath(@__DIR__, "test_pages", "text_content.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test static text content
        content = wait_for_visible(ElementHandle(client, "#content"))
        @test !isempty(get_text(content))

        # Test dynamic text content
        dynamic = wait_for_visible(ElementHandle(client, "#dynamic-content"))
        initial_text = get_text(dynamic)
        button = wait_for_visible(ElementHandle(client, "#update-button"))
        @test click(button)
        sleep(1)  # Allow for content update
        @test get_text(dynamic) != initial_text
    end

    @testset "Radio Buttons" begin
        # Test radio_buttons.html
        local_path = joinpath(@__DIR__, "test_pages", "radio_buttons.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test radio button selection
        radio1 = wait_for_visible(ElementHandle(client, "#radio1"))
        radio2 = wait_for_visible(ElementHandle(client, "#radio2"))

        @test check(radio1)
        sleep(0.5)  # Allow for state change
        @test evaluate_handle(radio1, "el.checked") == true
        @test evaluate_handle(radio2, "el.checked") == false

        @test check(radio2)
        sleep(0.5)  # Allow for state change
        @test evaluate_handle(radio1, "el.checked") == false
        @test evaluate_handle(radio2, "el.checked") == true
    end

    @testset "Element Evaluation" begin
        # Test element_evaluate.html
        local_path = joinpath(@__DIR__, "test_pages", "element_evaluate.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test attribute retrieval
        element = wait_for_visible(ElementHandle(client, "#test-div"))
        @test get_attribute(element, "data-custom") == "test-data"
        @test get_attribute(element, "nonexistent") === nothing

        # Test complex evaluation with retry
        let attempts = 3
            while attempts > 0
                try
                    @test evaluate(client, """(() => {
                        const el = document.querySelector('#test-div');
                        const rect = el.getBoundingClientRect();
                        return rect.width > 0 && rect.height > 0;
                    })()""") == true
                    break
                catch
                    attempts -= 1
                    sleep(1)
                    attempts > 0 || rethrow()
                end
            end
        end
    end

    @testset "Form Validation" begin
        # Test form_validation.html
        local_path = joinpath(@__DIR__, "test_pages", "form_validation.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test required field validation
        input = wait_for_visible(ElementHandle(client, "#required-input"))
        submit = wait_for_visible(ElementHandle(client, "#submit-button"))

        @test click(submit)
        sleep(0.5)  # Allow for validation
        @test evaluate_handle(input, "el.validity.valid") == false

        @test type_text(input, "valid input")
        sleep(0.5)  # Allow for input processing
        @test click(submit)
        sleep(0.5)  # Allow for validation
        @test evaluate_handle(input, "el.validity.valid") == true
    end

    @testset "Dynamic Content and Visibility" begin
        local_path = joinpath(@__DIR__, "test_pages", "dynamic_content.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test delayed content visibility
        delayed = ElementHandle(client, "#delayed-content")
        @test !is_visible(delayed)

        show_button = wait_for_visible(ElementHandle(client, "#show-delayed"))
        @test click(show_button)

        # Wait for animation with retry
        let attempts = 3
            while attempts > 0
                sleep(0.5)
                if is_visible(delayed)
                    break
                end
                attempts -= 1
                attempts > 0 || error("Element did not become visible")
            end
        end
        @test is_visible(delayed)

        # Test dynamic content updates
        dynamic = wait_for_visible(ElementHandle(client, "#dynamic-content"))
        initial_content = get_text(dynamic)

        update_button = wait_for_visible(ElementHandle(client, "#update-button"))
        @test click(update_button)
        sleep(1)  # Allow for content update
        @test get_text(dynamic) != initial_content
    end

    @testset "Complex Form Interactions" begin
        local_path = joinpath(@__DIR__, "test_pages", "complex_form.html")
        url = "file://" * local_path
        goto(client, url)
        wait_for_ready_state(client)

        # Test username validation
        username = wait_for_visible(ElementHandle(client, "#username"))
        error_msg = ElementHandle(client, "#username-error")

        @test type_text(username, "ab")  # Too short
        sleep(0.5)  # Allow for validation
        @test evaluate(
            client, "document.getElementById('username').dispatchEvent(new Event('input'))") !==
              nothing
        sleep(0.5)  # Allow for error message
        @test is_visible(error_msg)

        @test type_text(username, "validuser")
        sleep(0.5)  # Allow for validation
        @test evaluate(
            client, "document.getElementById('username').dispatchEvent(new Event('input'))") !==
              nothing
        sleep(0.5)  # Allow for error message
        @test !is_visible(error_msg)

        # Test checkboxes
        pref1 = wait_for_visible(ElementHandle(client, "#pref1"))
        pref2 = wait_for_visible(ElementHandle(client, "#pref2"))

        @test check(pref1)
        @test check(pref2)
        sleep(0.5)  # Allow for state change
        @test evaluate_handle(pref1, "el.checked") == true
        @test evaluate_handle(pref2, "el.checked") == true

        # Test select dropdown
        select = wait_for_visible(ElementHandle(client, "#notification-type"))
        @test select_option(select, "weekly")
        sleep(0.5)  # Allow for selection
        @test evaluate_handle(select, "el.value") == "weekly"

        # Test form submission
        submit = wait_for_visible(ElementHandle(client, "#submit-form"))
        result = wait_for_visible(ElementHandle(client, "#form-result"),
            visible = false)

        @test click(submit)
        sleep(1)  # Allow for form submission and result display
        @test is_visible(result)
    end
end
