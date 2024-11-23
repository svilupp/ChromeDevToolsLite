using ChromeDevToolsLite
using Test

const TEST_PORT = 9222
const TEST_ENDPOINT = "http://localhost:$TEST_PORT"

@testset "HTTP-Specific Tests" begin
    browser = Browser(TEST_ENDPOINT)
    page = nothing

    @testset "HTTP Endpoint Validation" begin
        @test_throws ArgumentError Browser("ws://localhost:9222")  # WebSocket URL not allowed
        @test_throws ArgumentError Browser("http://")  # Invalid URL
        @test Browser("http://localhost:9222").endpoint == "http://localhost:9222"
    end

    @testset "HTTP Response Handling" begin
        page = new_page(browser)
        try
            # Test HTTP 404 handling
            result = execute_cdp_method(browser, page, "NonexistentMethod", Dict())
            @test haskey(result, "error")

            # Test malformed JSON response handling
            result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => "(() => { return undefined })()",
                "returnByValue" => true
            ))
            @test haskey(result, "result")

            # Test large response handling
            result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => """
                    "a".repeat(1000000)  // 1MB string
                """,
                "returnByValue" => true
            ))
            @test haskey(result, "result")
            @test length(result["result"]["value"]) == 1000000
        finally
            close_page(browser, page)
        end
    end

    @testset "HTTP Method Constraints" begin
        page = new_page(browser)
        try
            # Test methods requiring WebSocket (should fail or be unavailable)
            methods_requiring_websocket = [
                "Runtime.addBinding",
                "Runtime.awaitPromise",
                "Page.setLifecycleEventsEnabled",
                "Runtime.enable"
            ]

            for method in methods_requiring_websocket
                result = execute_cdp_method(browser, page, method, Dict())
                @test haskey(result, "error")
            end

            # Test valid HTTP methods
            valid_methods = [
                ("Page.navigate", Dict("url" => "https://example.com")),
                ("Runtime.evaluate", Dict("expression" => "document.title", "returnByValue" => true)),
                ("Page.reload", Dict()),
            ]

            for (method, params) in valid_methods
                result = execute_cdp_method(browser, page, method, params)
                @test !haskey(result, "error")
            end
        finally
            close_page(browser, page)
        end
    end

    @testset "Error Recovery" begin
        page = new_page(browser)
        try
            # Test recovery after JavaScript error
            result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => "throw new Error('test error')"
            ))
            @test haskey(result, "error")

            # Verify we can still execute commands
            result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => "123",
                "returnByValue" => true
            ))
            @test result["result"]["value"] == 123

            # Test recovery after navigation error
            result = execute_cdp_method(browser, page, "Page.navigate", Dict(
                "url" => "https://nonexistent.example.com"
            ))
            sleep(1)

            # Verify we can still navigate successfully
            result = execute_cdp_method(browser, page, "Page.navigate", Dict(
                "url" => "https://example.com"
            ))
            @test !haskey(result, "error")
        finally
            close_page(browser, page)
        end
    end
end
