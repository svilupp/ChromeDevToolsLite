using Test
using ChromeDevToolsLite
using TestUtils

@testset "Browser Base methods" begin
    # Test browser launch and initialization
    browser = launch_browser()

    # Test browser properties
    @test browser.process isa BrowserProcess
    @test browser.session isa CDPSession
    @test browser.options["headless"] == true
    @test isempty(browser.contexts)

    # Test show method
    @test sprint(show, browser) == "Browser(contexts=0)"

    # Test context management
    @test isempty(contexts(browser))

    # Create new context
    context = new_context(browser)
    @test context isa BrowserContext
    @test length(contexts(browser)) == 1
    @test contexts(browser)[1] === context
    @test context.id isa String  # Context ID should be set

    # Test close method
    close(browser)
    @test !isopen(browser.session.ws)
    @test_throws Base.ProcessFailedException run(`ps -p $(browser.process.pid)`)
end
