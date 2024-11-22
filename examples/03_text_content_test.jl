using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

try
    # Get the absolute path to our test page
    test_page_path = joinpath(dirname(@__FILE__), "test_pages", "text_content.html")
    test_page_url = "file://" * test_page_path

    @info "Starting text content test..."

    # Navigate to test page
    goto(page, test_page_url)
    wait_for_load(page)

    # Test static content
    static_content = get_text(page, "#static-content")
    @info "Static content:" static_content
    @assert static_content == "Static Text Content" "Static content mismatch"

    # Test immediate dynamic content
    dynamic_content = get_text(page, "#dynamic-content")
    @info "Immediate dynamic content:" dynamic_content
    @assert dynamic_content == "Changed Content" "Immediate dynamic content mismatch"

    # Wait for delayed content change
    sleep(1.5)  # Wait longer than the setTimeout delay
    final_content = get_text(page, "#dynamic-content")
    @info "Final dynamic content:" final_content
    @assert final_content == "Final Content" "Final dynamic content mismatch"

    @info "✓ Text content test successful"
finally
    # Cleanup
    close(page)
    close(browser)
end
