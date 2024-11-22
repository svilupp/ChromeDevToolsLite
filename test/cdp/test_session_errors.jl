using Test
using ChromeDevToolsLite
using TestUtils

@testset "CDP Session Error Handling" begin
    @testset "Connection errors" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Test sending message to closed session
        close(session)
        @test_throws ConnectionError send_message(session, create_cdp_message("Test.method"))

        # Test malformed JSON response
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)
        mock_ws.next_message = "invalid json"
        msg = create_cdp_message("Test.method")
        response_channel = send_message(session, msg)
        @test_throws ConnectionError take!(response_channel)
    end

    @testset "CDP Protocol errors" begin
        mock_ws = MockWebSocket()
        session = CDPSession(mock_ws)

        # Test navigation error
        mock_ws.next_response = Dict(
            "id" => 1,
            "error" => Dict(
                "code" => -1,
                "message" => "Navigation failed: timeout"
            )
        )
        msg = create_cdp_message("Page.navigate")
        response_channel = send_message(session, msg)
        @test_throws NavigationError take!(response_channel)

        # Test element not found error
        mock_ws.next_response = Dict(
            "id" => 2,
            "error" => Dict(
                "code" => -1,
                "message" => "Node not found"
            )
        )
        msg = create_cdp_message("DOM.querySelector")
        response_channel = send_message(session, msg)
        @test_throws ElementNotFoundError take!(response_channel)
    end
end
