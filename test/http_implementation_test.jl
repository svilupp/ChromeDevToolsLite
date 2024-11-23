using Test
using ChromeDevToolsLite

@testset "HTTP-only Implementation Tests" begin
    # Test browser connection
    @testset "Browser Connection" begin
        browser = connect_browser("http://localhost:9224")
        @test browser isa Browser
        @test browser.endpoint == "http://localhost:9224"
    end

    # Test page management
    @testset "Page Management" begin
        browser = connect_browser("http://localhost:9224")

        # Test new page creation
        page = new_page(browser)
        @test page isa Page
        @test !isempty(page.id)
        @test page.url == "about:blank"

        # Test page listing
        pages = get_pages(browser)
        @test pages isa Vector{Page}
        @test any(p -> p.id == page.id, pages)

        # Test navigation via CDP method
        result = execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))
        @test haskey(result, "frameId")

        # Test JavaScript evaluation
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict("expression" => "document.title"))
        @test haskey(result, "result")

        # Test page closing
        close_page(browser, page)
        pages = get_pages(browser)
        @test !any(p -> p.id == page.id, pages)
    end

    # Test error handling
    @testset "Error Handling" begin
        browser = connect_browser("http://localhost:9224")
        page = new_page(browser)

        # Test unsupported CDP method
        @test_throws ErrorException execute_cdp_method(browser, page, "Network.enable", Dict())

        close_page(browser, page)
    end
end
