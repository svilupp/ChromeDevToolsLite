
@testset "ChromeDevToolsLite Basic Tests" begin
    client = connect_browser(ENDPOINT)

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
end
