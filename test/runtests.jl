using ChromeDevToolsLite
using Test
using HTTP
using Logging
using Aqua

# Configure test logging
# ENV["JULIA_DEBUG"] = "ChromeDevToolsLite"
# logger = ConsoleLogger(stderr, Logging.Debug)
# global_logger(logger)
const ENDPOINT = "http://localhost:9222"
const MAX_SETUP_RETRIES = 3
const SETUP_RETRY_DELAY = 2.0

include("test_utils.jl")

function ensure_clean_environment()
    cleanup()  # Clean any existing Chrome instances
    sleep(1)   # Give system time to clean up processes
end

function setup_test_environment()
    for attempt in 1:MAX_SETUP_RETRIES
        try
            ensure_clean_environment()
            client = setup_test()
            @info "Test environment setup successful on attempt $attempt"
            return client
        catch e
            @warn "Failed to setup test environment (attempt $attempt)" exception=e
            if attempt == MAX_SETUP_RETRIES
                rethrow(e)
            end
            sleep(SETUP_RETRY_DELAY)
        end
    end
end

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ChromeDevToolsLite)
    end

    client = nothing
    try
        client = setup_test_environment()

        # Run browser-specific tests first
        include("browser_test.jl")

        # Run legacy client-based tests
        include("basic_test.jl")
        include("websocket_test.jl")
        include("element_test.jl")
        include("comprehensive_test.jl")
    finally
        if client !== nothing
            teardown_test(client)
        end
        cleanup()
    end
end
