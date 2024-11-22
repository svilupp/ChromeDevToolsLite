using ChromeDevToolsLite
using Test

@info "Starting browser launch test..."

# Launch a new browser instance with error handling
browser = nothing
try
    browser = launch_browser()
    @test browser isa Browser
    @info "✓ Browser launched successfully"

    # Create a new browser context (like an incognito window)
    context = new_context(browser)
    @test context isa BrowserContext
    @info "✓ Browser context created"

    # Create a new page in the context
    page = new_page(context)
    @test page isa Page
    @info "✓ New page created"

    # Navigate to a website
    goto(page, "https://example.com")
    @test get_url(page) == "https://example.com/"
    @info "✓ Navigated to example.com"
    @info "Current URL: $(get_url(page))"

catch e
    @error "Test failed" exception=e
    rethrow(e)
finally
    # Clean up resources
    if !isnothing(browser)
        try
            close(browser)
            @info "✓ Resources cleaned up"
        catch e
            @error "Failed to clean up resources" exception=e
        end
    end
end
