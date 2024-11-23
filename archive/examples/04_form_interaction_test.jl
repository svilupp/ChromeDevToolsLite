using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

try
    # Get the absolute path to our test page
    test_page_path = joinpath(dirname(@__FILE__), "test_pages", "form_interaction.html")
    test_page_url = "file://" * test_page_path

    @info "Starting form interaction test..."
    goto(page, test_page_url)
    wait_for_load(page)

    # Test text input
    type_text(page, "#text-input", "Hello World")
    value = get_value(page, "#text-input")
    @assert value == "Hello World" "Text input value mismatch"
    @info "✓ Text input test passed"

    # Test checkbox
    @assert !is_checked(page, "#check-input") "Checkbox should be unchecked initially"
    click(page, "#check-input")
    @assert is_checked(page, "#check-input") "Checkbox should be checked after click"
    @info "✓ Checkbox test passed"

    # Test select
    select_option(page, "#select-input", "2")
    value = get_value(page, "#select-input")
    @assert value == "2" "Select value mismatch"
    @info "✓ Select test passed"

    # Test form submission and visibility
    @assert !is_visible(page, "#result") "Result should be hidden initially"
    click(page, "#submit-btn")
    sleep(0.5) # Wait for animation
    @assert is_visible(page, "#result") "Result should be visible after submission"
    @info "✓ Form submission test passed"

    @info "✓ Form interaction test successful"
finally
    # Cleanup
    close(page)
    close(browser)
end
