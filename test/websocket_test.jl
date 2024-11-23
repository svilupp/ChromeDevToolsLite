using Test
using ChromeDevToolsLite
using HTTP
using JSON3

@testset "WebSocket Connection Tests" begin
    # Test basic connection
    client = connect_browser()
    @test client isa WSClient
    @test !isnothing(client.ws)
    @test client.id == 1
    @test !client.page_loaded

    # Test page navigation
    response = send_cdp_message(client, "Page.navigate", Dict("url" => "https://www.example.com"))
    @test haskey(response, "result")

    # Wait for page load
    sleep(2)  # Give page time to load
    @test client.page_loaded

    # Test JavaScript evaluation
    eval_response = send_cdp_message(client, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))
    @test haskey(eval_response, "result")
    @test haskey(eval_response["result"], "result")
    @test haskey(eval_response["result"]["result"], "value")
    @test eval_response["result"]["result"]["value"] == "Example Domain"

    # Test connection closure
    close(client)
    @test isnothing(client.ws)
end
