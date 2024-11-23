using ChromeDevToolsLite
using Test
using HTTP
using Logging

# Set up logging
ENV["JULIA_DEBUG"] = "ChromeDevToolsLite"

function setup_test()
    @debug "Setting up test environment"
    sleep(2.0)  # Increased delay to give Chrome more time to stabilize
    return nothing
end

function teardown_test()
    @debug "Tearing down test environment"
    sleep(2.0)  # Increased delay for cleanup
    return nothing
end

@testset "ChromeDevToolsLite Basic Tests" begin
    @testset "WebSocket Connection" begin
        setup_test()

        @debug "Creating WebSocket client"
        client = WSClient("ws://localhost:9222/devtools/page/$(get_ws_id())")
        @test client isa WSClient

        @debug "Connecting client"
        connect!(client)
        @test client.is_connected
        @test !isnothing(client.ws)

        close(client)
        teardown_test()
    end

    @testset "CDP Commands" begin
        setup_test()

        @info "Ensuring Chrome is ready"
        # More robust Chrome readiness check
        for attempt in 1:5
            @info "Chrome readiness check attempt $attempt/5"
            if ensure_chrome_running(max_attempts=3, delay=2.0)
                break
            elseif attempt == 5
                error("Chrome failed to start properly after multiple attempts")
            end
            sleep(2.0)
        end

        @debug "Connecting to Chrome DevTools"
        client = nothing
        try
            # Multiple attempts to get WebSocket ID
            local ws_id
            for attempt in 1:3
                try
                    ws_id = get_ws_id()
                    @info "Retrieved WebSocket ID" ws_id=ws_id
                    break
                catch e
                    if attempt == 3
                        @error "Failed to get WebSocket ID after 3 attempts" exception=e
                        rethrow(e)
                    end
                    sleep(1.0)
                end
            end

            # Connect with retry
            for attempt in 1:3
                try
                    client = connect_cdp("ws://localhost:9222/devtools/page/$ws_id")
                    @test client isa WSClient
                    @test client.is_connected
                    break
                catch e
                    if attempt == 3
                        @error "Failed to connect to CDP after 3 attempts" exception=e
                        rethrow(e)
                    end
                    sleep(1.0)
                end
            end

            @debug "Testing Page.enable command"
            response = send_cdp_message(client, "Page.enable")
            @info "CDP Response received" response=response

            # Enhanced response validation with detailed logging
            @test isa(response, Dict) || begin
                @error "Invalid response type" type=typeof(response) response=response
                error("Expected Dict response, got $(typeof(response))")
            end

            @test (haskey(response, "result") || haskey(response, "error")) || begin
                @error "Invalid response format" response=response
                error("Response must contain either 'result' or 'error' field")
            end

            if haskey(response, "error")
                @error "CDP command failed" error=response["error"]
                error("Page.enable command failed: $(response["error"])")
            end

            @test haskey(response, "result") "Response must contain 'result' field"
            @debug "Page.enable successful" result=response["result"]
        catch e
            @error "CDP test failed" exception=e stacktrace=stacktrace()
            rethrow(e)
        finally
            if client !== nothing
                close(client)
            end
            teardown_test()
        end
    end

    @testset "Page Navigation" begin
        setup_test()

        client = WSClient("ws://localhost:9222/devtools/page/$(get_ws_id())")
        connect!(client)

        @debug "Enabling required domains"
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Runtime.enable")

        @debug "Navigating to example.com"
        response = send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        @test haskey(response, "result") || error("Navigation failed: $response")
        @test haskey(response["result"], "frameId") || error("No frameId in response: $response")

        sleep(1)  # Wait for page load

        @debug "Evaluating page title"
        eval_response = send_cdp_message(client, "Runtime.evaluate", Dict{String, Any}(
            "expression" => "document.title",
            "returnByValue" => true
        ))

        @test haskey(eval_response, "result") || error("Evaluation failed: $eval_response")
        @test haskey(eval_response["result"], "result") || error("No result in evaluation: $eval_response")
        result_value = get(get(get(eval_response, "result", Dict()), "result", Dict()), "value", nothing)
        @test result_value == "Example Domain" || error("Unexpected title: $result_value")

        close(client)
        teardown_test()
    end

    @testset "Screenshots" begin
        setup_test()

        client = WSClient("ws://localhost:9222/devtools/page/$(get_ws_id())")
        connect!(client)

        # Enable Page domain and navigate
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))

        # Add a small delay to ensure page is loaded
        sleep(1)

        # Take screenshot
        response = send_cdp_message(client, "Page.captureScreenshot")
        @test haskey(response, "result") || error("Screenshot failed: $response")
        @test haskey(response["result"], "data") || error("No image data in response: $response")
        close(client)
    end
end
