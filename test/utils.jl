@testset "utils.jl" begin
    # Test extract_cdp_result with simple path
    response = Dict("result" => Dict("result" => Dict("value" => 42)))
    @test extract_cdp_result(response) == 42

    # Test extract_cdp_result with empty path
    @test extract_cdp_result(Dict("value" => 123), ["value"]) == 123

    # Test extract_cdp_result with non-existent path
    @test extract_cdp_result(Dict(), ["nonexistent"]) === nothing

    # Test extract_cdp_result with nested value object
    @test extract_cdp_result(Dict("result" => Dict("result" => Dict("value" => Dict("value" => "nested"))))) ==
          "nested"

    # Test extract_element_result with standard CDP path
    @test extract_element_result(Dict("result" => Dict("result" => Dict("value" => "test")))) ==
          "test"

    # Test extract_element_result with success/value pattern
    response = Dict("result" => Dict("result" => Dict("value" => Dict(
        "success" => true, "value" => "success"))))
    @test extract_element_result(response) == "success"

    # Test extract_element_result with failed success/value pattern
    response = Dict("result" => Dict("result" => Dict("value" => Dict(
        "success" => false, "value" => "fail"))))
    @test extract_element_result(response) === "fail"

    # Test extract_element_result with fallback paths
    @test extract_element_result(Dict("result" => "direct")) == "direct"

    # Test with_retry success on first try
    counter = Ref(0)
    result = with_retry(verbose = true) do
        counter[] += 1
        42
    end
    @test result == 42
    @test counter[] == 1

    # Test with_retry success after failures
    counter = Ref(0)
    result = with_retry(max_retries = 3, retry_delay = 0.01, verbose = true) do
        counter[] += 1
        if counter[] < 2
            error("Simulated failure")
        end
        "success"
    end
    @test result == "success"
    @test counter[] == 2

    # Test with_retry exhausting all retries
    counter = Ref(0)
    @test_throws ErrorException with_retry(
        max_retries = 2, retry_delay = 0.01, verbose = true) do
        counter[] += 1
        error("Simulated failure")
    end
    @test counter[] == 2
end
