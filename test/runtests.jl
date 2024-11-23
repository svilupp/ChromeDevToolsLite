using ChromeDevToolsLite
using Test

const TEST_PORT = 9222
const TEST_ENDPOINT = "http://localhost:$TEST_PORT"

@testset "ChromeDevToolsLite.jl" begin
    @testset "Browser Construction" begin
        @test_throws ArgumentError Browser("")
        browser = Browser(TEST_ENDPOINT)
        @test browser.endpoint == TEST_ENDPOINT
        @test sprint(show, browser) == "Browser(endpoint=\"$TEST_ENDPOINT\")"
    end

    if haskey(ENV, "CI")
        @warn "Skipping browser integration tests in CI environment"
    else
        include("http_specific_tests.jl")
        include("state_management_test.jl")

        @testset "Browser Integration" begin
            browser = Browser(TEST_ENDPOINT)

            @testset "Page Management" begin
                # Test page creation with URL
                test_url = "about:blank"
                page = new_page(browser, test_url)
                @test page.url == test_url
                @test page.id isa String
                @test !isempty(page.id)

                # Test page listing
                pages = get_pages(browser)
                @test any(p -> p.id == page.id, pages)

                # Test page closure
                close_page(browser, page)
                updated_pages = get_pages(browser)
                @test !any(p -> p.id == page.id, updated_pages)
            end

            @testset "CDP Method Execution" begin
                page = new_page(browser)
                try
                    # Basic navigation test
                    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
                        "url" => "https://example.com"
                    ))
                    @test !haskey(result, "error")
                    sleep(1)

                    # Verify navigation success
                    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                        "expression" => "document.readyState === 'complete'",
                        "returnByValue" => true
                    ))
                    @test result["result"]["value"] == true

                    # Test complex JavaScript evaluation
                    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                        "expression" => """
                            ({
                                title: document.title,
                                url: window.location.href,
                                h1: document.querySelector('h1')?.textContent,
                                links: document.links.length
                            })
                        """,
                        "returnByValue" => true
                    ))
                    @test haskey(result, "result")
                    @test haskey(result["result"]["value"], "title")
                    @test haskey(result["result"]["value"], "url")

                    # Test DOM manipulation
                    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                        "expression" => """
                            const div = document.createElement('div');
                            div.id = 'test-div';
                            div.textContent = 'Test Content';
                            document.body.appendChild(div);
                            return document.getElementById('test-div')?.textContent;
                        """,
                        "returnByValue" => true
                    ))
                    @test result["result"]["value"] == "Test Content"

                    # Test error cases
                    @testset "Error Handling" begin
                        # Invalid JavaScript
                        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                            "expression" => "invalid javascript }"
                        ))
                        @test haskey(result, "error")

                        # Invalid method
                        @test_throws ArgumentError execute_cdp_method(browser, page, "", Dict())

                        # Invalid selector
                        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                            "expression" => "document.querySelector('#nonexistent').textContent",
                            "returnByValue" => true
                        ))
                        @test haskey(result, "error")
                    end
                finally
                    close_page(browser, page)
                end
            end
        end
    end
end
