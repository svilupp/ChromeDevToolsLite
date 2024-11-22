using Test
using ChromeDevToolsLite
using TestUtils

@testset "CDP Session" begin
    @testset "Basic Session Operations" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Test session creation
        @test session.ws === mock_ws
        @test !session.is_closed[]
        @test isempty(session.callbacks)
        @test isempty(session.event_listeners)

        # Test session closure
        close(session)
        @test session.is_closed[]
        @test isempty(session.callbacks)
        @test isempty(session.event_listeners)
    end

    @testset "Message Sending and Response Handling" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Create and send a test message
        request = create_cdp_message("Page.navigate", Dict("url" => "https://example.com"))
        response_channel = send_message(session, request)

        # Simulate response from browser
        response_data = Dict(
            "id" => request.id,
            "result" => Dict("frameId" => "123")
        )
        write(mock_ws.io, JSON3.write(response_data))
        seekstart(mock_ws.io)

        # Check if response is received
        response = take!(response_channel)
        @test response.id == request.id
        @test response.result["frameId"] == "123"
        @test isnothing(response.error)

        close(session)
    end

    @testset "Event Listeners" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Test event listener registration
        event_received = Channel{Bool}(1)
        callback = params -> put!(event_received, true)

        add_event_listener(session, "Page.loadEventFired", callback)
        @test length(session.event_listeners["Page.loadEventFired"]) == 1

        # Simulate event from browser
        event_data = Dict(
            "method" => "Page.loadEventFired",
            "params" => Dict("timestamp" => 123.45)
        )
        write(mock_ws.io, JSON3.write(event_data))
        seekstart(mock_ws.io)

        # Check if event callback is triggered
        @test fetch(event_received)

        # Test event listener removal
        remove_event_listener(session, "Page.loadEventFired", callback)
        @test isempty(session.event_listeners["Page.loadEventFired"])

        close(session)
    end
end
