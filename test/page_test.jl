using Test
using ChromeDevToolsLite

@testset "Page Operations Tests" begin
    client = nothing
    try
        # Initialize client
        client = connect_browser(verbose=true)

        @testset "Basic Page Operations" begin
            # Test navigation
            test_url = "file://" * joinpath(@__DIR__, "test_pages", "error_cases.html")
            @test goto(client, test_url) === nothing

            # Test invalid navigation
            @test_throws NavigationError goto(client, "file:///nonexistent.html")

            # Test content retrieval
            content_result = content(client)
            @test content_result isa String
            @test contains(content_result, "<title>Error Cases Test</title>")

            # Test JavaScript evaluation
            @test evaluate(client, "42") == 42
            @test evaluate(client, "undefined") === nothing
            @test evaluate(client, "null") === nothing

            # Test error handling - these should return nothing for any JS errors
            @test evaluate(client, "throwError()") === nothing
            @test evaluate(client, "nonexistent.variable") === nothing

            # Test screenshot functionality
            screenshot_result = screenshot(client)
            @test screenshot_result isa String
            @test startswith(screenshot_result, "iVBOR")

            # Test page modifications
            @test evaluate(client, "document.body.style.background = 'red'") !== nothing
            modified_screenshot = screenshot(client)
            @test modified_screenshot != screenshot_result

            # Test error handling - syntax errors should also return nothing
            @test evaluate(client, "invalid.syntax..") === nothing
            @test evaluate(client, "throw new Error('test')") === nothing
        end

    finally
        # Cleanup
        if client !== nothing
            close(client)
        end
    end
end
