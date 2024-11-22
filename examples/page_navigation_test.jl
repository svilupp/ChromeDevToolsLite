using ChromeDevToolsLite
using Test

# Start browser and create a new page
browser = launch_browser(headless=true)
context = new_context(browser)
page = new_page(context)

# Get the absolute path to our test page
test_page_path = joinpath(@__DIR__, "test_pages", "static_test.html")
test_page_url = "file://" * test_page_path

@testset "Page Navigation Tests" begin
    # Test basic navigation
    @test begin
        goto(page, test_page_url)
        sleep(1)  # Give it a moment to load
        title = evaluate(page, "document.title")
        @info "Page title: $title"
        title == "Static Test Page"
    end

    # Test content retrieval
    @test begin
        content_html = content(page)
        @info "Page content length: $(length(content_html))"
        contains(content_html, "Test Page Header")
    end

    # Test element visibility
    @test begin
        visible_el = query_selector(page, "#visible-element")
        hidden_el = query_selector(page, "#hidden-element")
        is_visible(visible_el) && !is_visible(hidden_el)
    end

    # Test element counting
    @test begin
        paragraphs = query_selector_all(page, ".test-paragraph")
        length(paragraphs) == 2
    end

    # Take a screenshot for verification
    screenshot_path = joinpath(@__DIR__, "test_output", "navigation_test.png")
    mkpath(dirname(screenshot_path))
    screenshot(page, path=screenshot_path)
    @info "Screenshot saved to: $screenshot_path"
end

# Cleanup
close(page)
close(context)
close(browser)
