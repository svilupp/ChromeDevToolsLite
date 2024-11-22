using Test
using ChromeDevToolsLite

@testset "Error handling utilities" begin
    @testset "handle_cdp_error" begin
        # Test protocol error
        protocol_error = Dict(
            "error" => Dict(
                "code" => -32000,
                "message" => "Connection closed"
            )
        )
        @test_throws ConnectionError handle_cdp_error(protocol_error)

        # Test invalid params
        invalid_params = Dict(
            "error" => Dict(
                "code" => -32602,
                "message" => "Invalid selector"
            )
        )
        @test_throws ArgumentError handle_cdp_error(invalid_params)

        # Test navigation error
        nav_error = Dict(
            "error" => Dict(
                "code" => -1,
                "message" => "Navigation failed: timeout"
            )
        )
        @test_throws NavigationError handle_cdp_error(nav_error)

        # Test element not found
        element_error = Dict(
            "error" => Dict(
                "code" => -1,
                "message" => "Node not found"
            )
        )
        @test_throws ElementNotFoundError handle_cdp_error(element_error)

        # Test evaluation error
        eval_error = Dict(
            "error" => Dict(
                "code" => -1,
                "message" => "Evaluation failed: ReferenceError"
            )
        )
        @test_throws EvaluationError handle_cdp_error(eval_error)

        # Test no error
        no_error = Dict("result" => "success")
        @test handle_cdp_error(no_error) === nothing
    end

    @testset "Error types" begin
        # Test error message preservation
        msg = "Test error message"
        @test ConnectionError(msg).msg == msg
        @test NavigationError(msg).msg == msg
        @test ElementNotFoundError(msg).msg == msg
        @test EvaluationError(msg).msg == msg
    end
end
