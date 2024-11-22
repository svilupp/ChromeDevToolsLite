using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

try
    # Test 1: Basic navigation with detailed logging
    @info "Starting navigation test..."

    # Register event listener before navigation
    @info "Setting up navigation..."
    goto(page, "https://example.com")

    @info "Waiting for page load..."
    wait_for_load(page)

    @info "Getting page title..."
    title = get_title(page)
    @info "Page title received" title

    @assert title == "Example Domain" "Expected title 'Example Domain', got '$title'"
    @info "✓ Navigation test successful"
finally
    # Cleanup
    @info "Cleaning up..."
    close(page)
    close(browser)
    @info "Cleanup complete"
end
