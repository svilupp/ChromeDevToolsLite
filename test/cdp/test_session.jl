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

        # Write response directly as a Dict to ensure proper JSON formatting
        response_data = Dict{String,Any}(
            "id" => request.id,
            "result" => Dict{String,Any}("frameId" => "123")
        )
        write(mock_ws.io, JSON3.write(response_data))
        seekstart(mock_ws.io)

        # Wait for response with timeout
        response = nothing
        @test timedwait(5.0) do
            if isready(response_channel)
                response = take!(response_channel)
                return true
            end
            return false
        end !== :timed_out "Response timeout"

        @test !isnothing(response) "Response should not be nothing"
        @test response.id == request.id "Response ID should match request ID"
        @test !isnothing(response.result) "Response result should not be nothing"
        @test response.result["frameId"] == "123" "Frame ID should match"

        # Cleanup
        close(session)
        @test session.is_closed[]
    end

    @testset "Event Listeners" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Test event listener registration
        event_received = Channel{Bool}(1)
        callback = params -> put!(event_received, true)

        add_event_listener(session, "Page.loadEventFired", callback)
        @test length(session.event_listeners["Page.loadEventFired"]) == 1

        # Simulate event
        event_data = Dict(
            "method" => "Page.loadEventFired",
            "params" => Dict("timestamp" => 123.45)
        )
        write(mock_ws.io, JSON3.write(event_data))
        seekstart(mock_ws.io)

        # Wait for event with timeout
        @test timedwait(5.0) do
            isready(event_received)
        end !== :timed_out
        @test take!(event_received)

        # Test event listener removal
        remove_event_listener(session, "Page.loadEventFired", callback)
        @test isempty(session.event_listeners["Page.loadEventFired"])

        close(session)
        @test session.is_closed[]
    end
end
