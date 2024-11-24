# Helper function for waiting on page load
function wait_for_page_load(client; timeout=10)
    start_time = time()
    while (time() - start_time) < timeout
        try
            response = send_cdp(client, "Runtime.evaluate",
                Dict("expression" => "document.readyState", "returnByValue" => true))
            if get(get(get(response, "result", Dict()), "result", Dict()), "value", "") == "complete"
                return true
            end
        catch
            # Ignore evaluation errors during page load
        end
        sleep(0.5)
    end
    error("Page load timeout after $timeout seconds")
end

@testset "ChromeDevToolsLite Basic Tests" begin
    client = connect_browser(ENDPOINT)

    @testset "CDP Commands" begin
        @debug "Testing Page.enable command"
        response = send_cdp(client, "Page.enable")
        @test isa(response, Dict)
        @test haskey(response, "id")
        @test haskey(response, "result")
    end

    @testset "Page Navigation" begin
        @debug "Enabling required domains"
        send_cdp(client, "Page.enable")
        send_cdp(client, "Runtime.enable")
        send_cdp(client, "Network.enable")  # Enable network events

        @debug "Navigating to example.com"
        response = send_cdp(
            client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        @test haskey(response, "result")
        @test haskey(response["result"], "frameId")

        # Wait for page load with proper timeout
        @test wait_for_page_load(client, timeout=15)

        # Verify navigation success
        current_url = send_cdp(client, "Runtime.evaluate",
            Dict("expression" => "window.location.href", "returnByValue" => true))
        @test contains(get(get(get(current_url, "result", Dict()), "result", Dict()), "value", ""), "example.com")

        @debug "Evaluating page title"
        eval_response = send_cdp(client, "Runtime.evaluate",
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
        # Enable required domains
        send_cdp(client, "Page.enable")
        send_cdp(client, "Network.enable")

        # Navigate with proper wait
        send_cdp(
            client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
        @test wait_for_page_load(client, timeout=15)

        # Ensure viewport is set
        send_cdp(client, "Emulation.setDeviceMetricsOverride",
            Dict("width" => 1024, "height" => 768, "deviceScaleFactor" => 1, "mobile" => false))

        # Take screenshot with error handling
        response = send_cdp(client, "Page.captureScreenshot")
        @test haskey(response, "result")
        @test haskey(response["result"], "data")
        @test !isempty(response["result"]["data"])
    end
end
