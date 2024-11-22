using ChromeDevToolsLite
using Test

@testset "Minimal Browser Test" begin
    # Start browser
    browser = launch_browser(headless=true)
    @info "Browser launched successfully"

    # Create context and page
    context = new_context(browser)
    @info "Context created"

    page = new_page(context)
    @info "Page created"

    # Navigate to a simple URL
    goto(page, "https://example.com")
    @info "Navigation completed"

    # Take a screenshot to verify
    screenshot_path = joinpath(@__DIR__, "test_output", "minimal.png")
    mkpath(dirname(screenshot_path))
    screenshot(page, path=screenshot_path)
    @info "Screenshot saved to: $screenshot_path"

    # Cleanup
    close(page)
    close(context)
    close(browser)
end
