using ChromeDevToolsLite
using Test

@time begin
    # Create a test HTML file
    html_content = """
    <!DOCTYPE html>
    <html>
    <body>
        <button id="testButton" class="clickable" data-test="value">Test Button</button>
        <input type="checkbox" id="testCheckbox" checked>
        <div id="counter" data-count="42">Counter: 0</div>
    </body>
    </html>
    """

    test_file = "test_pages/evaluate_handle_test.html"
    mkpath(dirname(test_file))
    write(test_file, html_content)

    # Start browser and navigate to test page
    browser = launch_browser(headless=true)
    context = new_context(browser)
    page = new_page(context)

    # Navigate to the test file
    file_url = "file://$(abspath(test_file))"
    goto(page, file_url)

    println("Testing evaluate_handle functionality...")

    # Test button properties
    button = query_selector(page, "#testButton")
    @test !isnothing(button)

    # Test getting element text
    text = evaluate_handle(button, "el => el.textContent")
    @test text == "Test Button"

    # Test getting data attribute
    data_test = evaluate_handle(button, "el => el.getAttribute('data-test')")
    @test data_test == "value"

    # Test checkbox state
    checkbox = query_selector(page, "#testCheckbox")
    @test !isnothing(checkbox)
    checkbox_checked = evaluate_handle(checkbox, "el => el.checked")
    @test checkbox_checked == true

    # Test complex evaluation
    counter = query_selector(page, "#counter")
    @test !isnothing(counter)

    # Get data attribute and convert to number
    count_value = evaluate_handle(counter, "el => parseInt(el.getAttribute('data-count'))")
    @test count_value == 42

    # Test modifying element
    evaluate_handle(counter, "el => { el.textContent = 'Counter: ' + el.getAttribute('data-count') }")
    updated_text = evaluate_handle(counter, "el => el.textContent")
    @test updated_text == "Counter: 42"

    println("✓ All evaluate_handle tests passed!")

    # Cleanup
    close(browser)
    rm(test_file)
end
