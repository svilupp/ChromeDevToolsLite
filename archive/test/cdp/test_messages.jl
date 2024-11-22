using Test
using ChromeDevToolsLite
using JSON3

@testset "CDP Messages" begin
    @testset "Message Creation" begin
        # Test CDPRequest creation
        req = create_cdp_message("Page.navigate", Dict("url" => "https://example.com"))
        @test req.method == "Page.navigate"
        @test req.params["url"] == "https://example.com"
        @test req.id > 0

        # Test sequential IDs
        req2 = create_cdp_message("Page.reload")
        @test req2.id == req.id + 1
    end

    @testset "Message Serialization" begin
        # Test Request serialization
        req = CDPRequest(1, "Page.navigate", Dict("url" => "https://example.com"))
        json_req = JSON3.write(req)
        @test JSON3.read(json_req, Dict) == Dict(
            "id" => 1,
            "method" => "Page.navigate",
            "params" => Dict("url" => "https://example.com")
        )

        # Test Response serialization
        resp = CDPResponse(1, Dict("frameId" => "123"), nothing)
        json_resp = JSON3.write(resp)
        @test JSON3.read(json_resp, Dict) == Dict(
            "id" => 1,
            "result" => Dict("frameId" => "123")
        )

        # Test Error Response serialization
        error_resp = CDPResponse(1, nothing, Dict("code" => 404, "message" => "Not found"))
        json_error = JSON3.write(error_resp)
        @test JSON3.read(json_error, Dict) == Dict(
            "id" => 1,
            "error" => Dict("code" => 404, "message" => "Not found")
        )

        # Test Event serialization
        event = CDPEvent("Page.loadEventFired", Dict("timestamp" => 123.45))
        json_event = JSON3.write(event)
        @test JSON3.read(json_event, Dict) == Dict(
            "method" => "Page.loadEventFired",
            "params" => Dict("timestamp" => 123.45)
        )
    end

    @testset "Message Parsing" begin
        # Test Request parsing
        req_data = Dict(
            "id" => 1,
            "method" => "Page.navigate",
            "params" => Dict("url" => "https://example.com")
        )
        req = parse_cdp_message(req_data)
        @test req isa CDPRequest
        @test req.id == 1
        @test req.method == "Page.navigate"
        @test req.params["url"] == "https://example.com"

        # Test Response parsing
        resp_data = Dict(
            "id" => 1,
            "result" => Dict("frameId" => "123")
        )
        resp = parse_cdp_message(resp_data)
        @test resp isa CDPResponse
        @test resp.id == 1
        @test resp.result["frameId"] == "123"
        @test isnothing(resp.error)

        # Test Error Response parsing
        error_data = Dict(
            "id" => 1,
            "error" => Dict("code" => 404, "message" => "Not found")
        )
        error_resp = parse_cdp_message(error_data)
        @test error_resp isa CDPResponse
        @test error_resp.id == 1
        @test isnothing(error_resp.result)
        @test error_resp.error["code"] == 404

        # Test Event parsing
        event_data = Dict(
            "method" => "Page.loadEventFired",
            "params" => Dict("timestamp" => 123.45)
        )
        event = parse_cdp_message(event_data)
        @test event isa CDPEvent
        @test event.method == "Page.loadEventFired"
        @test event.params["timestamp"] == 123.45
    end
end
