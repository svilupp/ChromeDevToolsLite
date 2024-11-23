using ChromeDevToolsLite
using Test
using HTTP

@testset "ChromeDevToolsLite Basic Tests" begin
    @testset "WebSocket Connection" begin
        client = connect_cdp("ws://localhost:9222/devtools/browser/$(get_ws_id())")
        @test client isa WSClient
        @test client.is_connected
        close(client)
    end

    @testset "CDP Commands" begin
        client = connect_cdp("ws://localhost:9222/devtools/browser/$(get_ws_id())")
        # Enable Page domain
        response = send_cdp_message(client, "Page.enable")
        @test haskey(response, "result")
        close(client)
    end

    @testset "Page Navigation" begin
        client = connect_cdp("ws://localhost:9222/devtools/browser/$(get_ws_id())")
        # Enable required domains
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Runtime.enable")

        # Navigate to example.com
        response = send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        @test haskey(response, "result") || error("Navigation failed: $response")
        @test haskey(response["result"], "frameId") || error("No frameId in response: $response")

        # Evaluate page title
        eval_response = send_cdp_message(client, "Runtime.evaluate", Dict{String, Any}(
            "expression" => "document.title",
            "returnByValue" => true
        ))
        @test haskey(eval_response, "result") || error("Evaluation failed: $eval_response")
        @test haskey(eval_response["result"], "result") || error("No result in evaluation: $eval_response")
        @test eval_response["result"]["result"]["value"] == "Example Domain" ||
              error("Unexpected title: $(eval_response["result"]["result"]["value"])")
        close(client)
    end

    @testset "Screenshots" begin
        client = connect_cdp("ws://localhost:9222/devtools/browser/$(get_ws_id())")
        # Enable Page domain and navigate
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))

        # Take screenshot
        response = send_cdp_message(client, "Page.captureScreenshot")
        @test haskey(response, "result") || error("Screenshot failed: $response")
        @test haskey(response["result"], "data") || error("No image data in response: $response")
        close(client)
    end
end
