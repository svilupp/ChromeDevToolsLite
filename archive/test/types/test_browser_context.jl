using Test
using ChromeDevToolsLite
using TestUtils

@testset "BrowserContext Base methods" begin
    # Launch browser for testing
    browser = launch_browser()
    context = new_context(browser)

    # Test initial state
    @test context.browser === browser
    @test isempty(pages(context))
    @test context.context_id isa String

    # Test new page creation
    page = new_page(context)
    @test page isa Page
    @test length(pages(context)) == 1
    @test pages(context)[1] === page
    @test page.target_id isa String

    # Create multiple pages
    page2 = new_page(context)
    @test length(pages(context)) == 2
    @test pages(context)[2] === page2

    # Test close method
    close(context)
    close(browser)
end
