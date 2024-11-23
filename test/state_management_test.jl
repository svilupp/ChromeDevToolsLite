using Test
using ChromeDevToolsLite

@testset "State Management Tests" begin
    browser = Browser("http://localhost:9222")
    page = nothing

    try
        page = new_page(browser)

        @testset "Page State Verification" begin
            # Test initial blank page state
            state = verify_page_state(browser, page)
            @test state !== nothing
            @test state["ready"] == true
            @test state["url"] == "about:blank"

            # Test navigation and state verification
            result = execute_cdp_method(browser, page, "Page.navigate", Dict(
                "url" => "https://example.com"
            ))
            @test !haskey(result, "error")

            state = verify_page_state(browser, page)
            @test state !== nothing
            @test state["ready"] == true
            @test occursin("example.com", state["url"])
            @test state["metrics"]["links"] ≥ 0
            @test state["metrics"]["forms"] ≥ 0
        end

        @testset "Batch Element Updates" begin
            # Create a form via JavaScript
            setup = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => """
                    const form = document.createElement('form');
                    form.innerHTML = `
                        <input id="username" type="text">
                        <input id="email" type="email">
                        <input id="password" type="password">
                    `;
                    document.body.appendChild(form);
                    true
                """,
                "returnByValue" => true
            ))
            @test !haskey(setup, "error")

            # Test batch updates
            updates = Dict(
                "#username" => "testuser",
                "#email" => "test@example.com",
                "#password" => "password123"
            )

            result = batch_update_elements(browser, page, updates)
            @test result isa Dict
            @test all(values(result))  # All updates should succeed

            # Verify updates via JavaScript
            verify = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
                "expression" => """
                    ({
                        username: document.querySelector('#username').value,
                        email: document.querySelector('#email').value,
                        password: document.querySelector('#password').value
                    })
                """,
                "returnByValue" => true
            ))
            @test !haskey(verify, "error")
            @test verify["result"]["value"]["username"] == "testuser"
            @test verify["result"]["value"]["email"] == "test@example.com"
            @test verify["result"]["value"]["password"] == "password123"
        end

    finally
        page !== nothing && close_page(browser, page)
    end
end
