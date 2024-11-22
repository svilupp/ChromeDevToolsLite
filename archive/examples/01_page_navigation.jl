using ChromeDevToolsLite
using Test
using HTTP
using Base64

# Start a simple HTTP server for our test page
const TEST_PORT = 8123
server = HTTP.serve!("127.0.0.1", TEST_PORT) do request
    return HTTP.Response(200, read(joinpath(@__DIR__, "..", "test", "test_pages", "basic.html")))
end

@info "Starting page navigation test..."

try
    # Launch browser
    browser = launch_browser(headless=true)
    @test browser isa Browser
    @info "✓ Browser launched successfully"

    # Create a new page
    context = create_browser_context(browser)
    page = create_page(context)
    @test page isa Page

    # Navigate to our test page
    test_url = "http://localhost:$TEST_PORT"
    goto(page, test_url)

    # Verify navigation
    current_url = url(page)
    @test current_url == test_url || current_url == test_url * "/"

    # Get page title
    title = get_title(page)
    @test title == "CDP Test Page"

    # Take a screenshot to verify the page loaded
    screenshot(page, "/tmp/test_page.png")
    @test isfile("/tmp/test_page.png")

    @info "✓ Page navigation test successful"

catch e
    @error "Test failed" exception=e
    rethrow(e)
finally
    # Cleanup
    if @isdefined page
        close(page)
    end
    if @isdefined context
        close(context)
    end
    if @isdefined browser
        close(browser)
    end
    close(server)
    @info "✓ Cleanup completed"
end
