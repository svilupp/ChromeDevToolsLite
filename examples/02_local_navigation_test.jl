using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

try
    # Get the absolute path to our test page
    test_page_path = joinpath(dirname(@__FILE__), "test_pages", "navigation_test.html")
    test_page_url = "file://" * test_page_path

    @info "Starting local navigation test..."
    @info "Navigating to test page: $test_page_url"

    # Test navigation
    goto(page, test_page_url)

    @info "Waiting for page load..."
    wait_for_load(page)

    # Wait for content to be updated by checking data-loaded attribute
    @info "Waiting for content to be updated..."
    result = evaluate(page, """
    let attempts = 0;
    const maxAttempts = 50;  // 5 seconds total
    return new Promise((resolve) => {
        const check = () => {
            const element = document.querySelector('#content');
            if (element && element.dataset.loaded === 'true') {
                resolve(true);
            } else if (attempts++ < maxAttempts) {
                setTimeout(check, 100);
            } else {
                resolve(false);
            }
        };
        check();
    });""")

    @assert result == true "Timeout waiting for content to be updated"

    # Verify navigation succeeded
    title = get_title(page)
    @info "Page title:" title
    @assert title == "Navigation Test Page" "Expected title 'Navigation Test Page', got '$title'"

    # Verify content loaded
    content = get_text(page, "#content")
    @info "Page content:" content
    @assert content == "Page Loaded Successfully" "Expected content 'Page Loaded Successfully', got '$content'"

    @info "✓ Local navigation test successful"
finally
    # Cleanup
    close(page)
    close(browser)
end
