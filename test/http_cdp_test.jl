using Test
using ChromeDevToolsLite
using HTTP
using JSON3

function run_http_cdp_tests(browser)
    @testset "HTTP CDP Implementation" begin
        @testset "Basic CDP Methods" begin
            page = nothing
            try
                page = new_page(browser)

                # Test navigation
                result = execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))
                @test !haskey(result, "error")

                sleep(1) # Wait for navigation

                # Test JavaScript evaluation
                result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                    "expression" => "document.title",
                    "returnByValue" => true
                ))
                @test haskey(result, "result")
                @test haskey(result["result"], "value")
            finally
                page !== nothing && close_page(browser, page)
            end
        end

        @testset "DOM Operations" begin
            page = nothing
            try
                # Create a test page with HTML content
                html_content = """
                data:text/html,
                <div id="test">
                    <h1>Test Header</h1>
                    <p class="para">P1</p>
                    <p class="para">P2</p>
                </div>
                """
                page = new_page(browser, html_content)

                # Test DOM operations via Runtime.evaluate
                result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                    "expression" => "document.querySelector('#test') !== null",
                    "returnByValue" => true
                ))
                @test haskey(result, "result")
                @test result["result"]["value"] == true

                # Test multiple elements query
                result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                    "expression" => "document.querySelectorAll('.para').length",
                    "returnByValue" => true
                ))
                @test haskey(result, "result")
                @test result["result"]["value"] == 2
            finally
                page !== nothing && close_page(browser, page)
            end
        end

        @testset "Error Handling" begin
            page = nothing
            try
                page = new_page(browser)

                # Test invalid CDP method
                result = execute_cdp_method(browser, page, "InvalidMethod", Dict())
                @test haskey(result, "error")

                # Test invalid JavaScript
                result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                    "expression" => "{ invalid javascript }",
                    "returnByValue" => true
                ))
                @test haskey(result, "error")
            finally
                page !== nothing && close_page(browser, page)
            end
        end
    end
end

# Export the test runner function
export run_http_cdp_tests
