using ChromeDevToolsLite
using Test

@testset "ChromeDevToolsLite.jl" begin
    # Test Browser construction
    @test_throws ArgumentError Browser("")
    browser = Browser("http://localhost:9222")
    @test browser.endpoint == "http://localhost:9222"

    # Test show method
    @test sprint(show, browser) == "Browser(endpoint=\"http://localhost:9222\")"

    # Note: The following tests require a running Chrome instance
    # They should be in a separate test group that can be skipped
    # if Chrome is not available
    if haskey(ENV, "CI")
        @warn "Skipping browser integration tests in CI environment"
    else
        @testset "Browser Integration" begin
            # These tests require Chrome to be running with remote debugging enabled
            # on port 9222. They should be run locally during development.
            browser = connect_browser()

            # Test page creation and listing
            initial_pages = get_pages(browser)
            new_test_page = new_page(browser)
            updated_pages = get_pages(browser)

            @test length(updated_pages) == length(initial_pages) + 1
            @test any(p -> p.id == new_test_page.id, updated_pages)

            # Clean up
            close_page(browser, new_test_page)
            final_pages = get_pages(browser)
            @test length(final_pages) == length(initial_pages)
        end
    end
end
