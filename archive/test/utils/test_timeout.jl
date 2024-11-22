using Test
using ChromeDevToolsLite

@testset "Timeout utilities" begin
    @testset "with_timeout" begin
        # Test successful execution within timeout
        result = with_timeout(100) do
            sleep(0.01)
            return 42
        end
        @test result == 42

        # Test timeout
        @test_throws TimeoutError with_timeout(100) do
            sleep(0.2)
            return 42
        end

        # Test error propagation
        @test_throws ErrorException with_timeout(100) do
            error("Test error")
        end
    end

    @testset "retry_with_timeout" begin
        # Test successful retry
        counter = Ref(0)
        result = retry_with_timeout(timeout=1000, interval=50) do
            counter[] += 1
            if counter[] < 3
                error("Not ready yet")
            end
            return "success"
        end
        @test result == "success"
        @test counter[] == 3

        # Test timeout after retries
        @test_throws TimeoutError retry_with_timeout(timeout=200, interval=50) do
            error("Never succeeds")
        end

        # Test immediate success
        result = retry_with_timeout(timeout=1000) do
            return "immediate"
        end
        @test result == "immediate"
    end
end
