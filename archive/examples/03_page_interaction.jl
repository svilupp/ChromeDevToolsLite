using ChromeDevToolsLite
using HTTP

# Start HTTP server to serve our test page
server = HTTP.serve!("127.0.0.1", 8125) do request
    if request.target == "/"
        return HTTP.Response(200, read(joinpath(@__DIR__, "..", "test", "test_pages", "form.html")))
    end
    return HTTP.Response(404)
end

try
    println("Starting browser automation test...")

    # Initialize browser and page
    browser = launch_browser()
    context = new_context(browser)
    page = new_page(context)

    println("Navigating to test page...")
    goto(page, "http://localhost:8125")

    # Verify page loaded correctly
    title = get_title(page)
    @assert title == "Test Form" "Expected page title 'Test Form', got '$title'"
    println("✓ Page loaded successfully")

    # Test form interactions
    println("\nTesting form interactions...")

    # Test type_text with proper waiting
    println("1. Testing text input...")
    type_text(page, "#name", "Julia Tester")
    value = get_value(page, "#name")
    @assert value == "Julia Tester" "Type text failed: Expected 'Julia Tester', got '$value'"
    println("✓ Text input successful")

    # Test select_option with proper waiting
    println("\n2. Testing dropdown selection...")
    select_option(page, "#color", "blue")
    selected = get_value(page, "#color")
    @assert selected == "blue" "Select option failed: Expected 'blue', got '$selected'"
    println("✓ Dropdown selection successful")

    # Test form submission
    println("\n3. Testing form submission...")
    evaluate(page, """document.querySelector('button[type="submit"]').click()""")

    # Wait for and verify result
    sleep(0.5) # Small delay for DOM update
    result_visible = is_visible(page, "#result")
    @assert result_visible "Result element not visible after form submission"

    result_text = get_text(page, "#result")
    @assert contains(result_text, "Julia Tester") && contains(result_text, "blue") "Form submission result incorrect"
    println("✓ Form submission successful")

    println("\n✓ All interaction tests passed!")
finally
    # Cleanup
    close(server)
    println("✓ Cleanup completed")
end
