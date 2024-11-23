function setup_test()
    @debug "Setting up test environment"
    sleep(0.5)  # Give Chrome time to stabilize

    # Ensure Chrome is ready
    for attempt in 1:5
        @info "Chrome readiness check attempt $attempt/5"
        if ensure_chrome_running(max_attempts = 3, delay = 2.0)
            break
        elseif attempt == 5
            error("Chrome failed to start properly after multiple attempts")
        end
        sleep(2.0)
    end

    # Connect with retry
    local client
    for attempt in 1:3
        try
            client = connect_browser("http://localhost:9222")
            @debug "Successfully connected to Chrome DevTools"
            return client
        catch e
            if attempt == 3
                @error "Failed to connect to CDP after 3 attempts" exception=e
                rethrow(e)
            end
            sleep(1.0)
        end
    end
    return client
end

function teardown_test(client)
    if client !== nothing
        close(client)
    end
    @debug "Tearing down test environment"
    sleep(0.5)  # Give Chrome time to clean up
end

@testset "ChromeDevToolsLite Basic Tests" begin
    client = setup_test()

    @testset "CDP Commands" begin
        @debug "Testing Page.enable command"
        response = send_cdp_message(client, "Page.enable")
        @test isa(response, Dict)
        @test haskey(response, "id")
        @test haskey(response, "result")
    end

    @testset "Page Navigation" begin
        @debug "Enabling required domains"
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Runtime.enable")

        @debug "Navigating to example.com"
        response = send_cdp_message(
            client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        @test haskey(response, "result")
        @test haskey(response["result"], "frameId")

        sleep(1)  # Wait for page load

        @debug "Evaluating page title"
        eval_response = send_cdp_message(client, "Runtime.evaluate",
            Dict{String, Any}(
                "expression" => "document.title",
                "returnByValue" => true
            ))

        @test haskey(eval_response, "result")
        @test haskey(eval_response["result"], "result")
        result_value = get(
            get(get(eval_response, "result", Dict()), "result", Dict()), "value", nothing)
        @test result_value == "Example Domain"
    end

    @testset "Screenshots" begin
        # Enable Page domain and navigate
        send_cdp_message(client, "Page.enable")
        send_cdp_message(
            client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        sleep(1)

        # Take screenshot
        response = send_cdp_message(client, "Page.captureScreenshot")
        @test haskey(response, "result")
        @test haskey(response["result"], "data")
    end

    teardown_test(client)
end
