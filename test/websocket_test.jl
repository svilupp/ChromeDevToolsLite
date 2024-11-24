# Helper function for robust page load waiting
function wait_for_load_event(client; timeout=15)
    start_time = time()
    while (time() - start_time) < timeout
        try
            response = send_cdp(client, "Runtime.evaluate",
                Dict("expression" => "document.readyState", "returnByValue" => true))
            if get(get(get(response, "result", Dict()), "result", Dict()), "value", "") == "complete"
                return true
            end
        catch e
            @debug "Wait for load error (non-critical)" exception=e
        end
        sleep(0.5)
    end
    return false
end

@testset "WebSocket Connection Tests" begin
    # Test basic connection
    client = connect_browser(ENDPOINT)
    @test client isa WSClient
    @test !isnothing(client.ws)
    @test client.next_id == 1
    @test client.page_loaded == false

    # Test connection status
    @test client.is_connected == true

    # Test reconnection capability
    @testset "Connection Recovery" begin
        # Force connection drop
        close(client.ws)
        sleep(1)

        # Test auto-reconnect on command
        response = send_cdp(client, "Page.enable")
        @test haskey(response, "result")
        @test client.is_connected
    end

    # Test domain enabling with retry
    @testset "Domain Enabling" begin
        for domain in ["Page", "Runtime", "Network"]
            response = nothing
            @test_nowarn for _ in 1:3
                try
                    response = send_cdp(client, "$(domain).enable")
                    break
                catch
                    sleep(1)
                end
            end
            @test haskey(response, "result")
        end
    end

    @testset "Navigation and Evaluation" begin
        # Navigate with proper error handling and waiting
        response = send_cdp(
            client, "Page.navigate", Dict{String, Any}("url" => "https://www.example.com"))
        @test haskey(response, "result")
        @test haskey(response["result"], "frameId")

        # Wait for page load with timeout
        @test wait_for_load_event(client)

        # Test JavaScript evaluation
        eval_response = send_cdp(client, "Runtime.evaluate",
            Dict{String, Any}(
                "expression" => "document.title",
                "returnByValue" => true
            ))

        @test haskey(eval_response, "result") ||
              error("JavaScript evaluation failed: $(eval_response)")
        @test haskey(eval_response["result"], "result") ||
              error("No result in evaluation response: $(eval_response)")
        @test haskey(eval_response["result"]["result"], "value") ||
              error("No value in evaluation result: $(eval_response["result"])")

        title = eval_response["result"]["result"]["value"]
        @test title == "Example Domain" || error("Unexpected page title: $title")
    end

    @testset "Timeout Handling" begin
        # Test various timeout scenarios
        @test_throws TimeoutError send_cdp(client, "Runtime.evaluate",
            Dict{String, Any}(
                "expression" => "new Promise(r => setTimeout(r, 1000))",
                "awaitPromise" => true
            ), timeout = 0.1)

        # Test recovery after timeout
        response = send_cdp(client, "Runtime.evaluate",
            Dict{String, Any}("expression" => "2 + 2", "returnByValue" => true))
        @test haskey(response, "result")
    end

    # Test connection closure
    close(client)
    @test isnothing(client.ws)
    @test client.is_connected == false
end
