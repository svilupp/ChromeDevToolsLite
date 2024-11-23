using ChromeDevToolsLite
using Test
using HTTP
using Logging

# Configure test logging
ENV["JULIA_DEBUG"] = "ChromeDevToolsLite"
logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)

include("setup_chrome.jl")
include("test_utils.jl")

# Global cleanup function
function cleanup()
    try
        if Sys.islinux()
            run(`pkill chrome`)
            sleep(1)  # Give time for process to terminate
        end
    catch
        # Ignore cleanup errors
    end
end

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    @info "Setting up Chrome for tests..."
    try
        # Try to set up Chrome
        setup_success = false
        setup_error = nothing

        try
            setup_success = setup_chrome()
        catch e
            setup_error = e
            @error "Chrome setup failed" exception=e
        end

        if !setup_success
            if setup_error !== nothing
                @error "Chrome setup failed" exception=setup_error
            end
            error("Failed to set up Chrome for testing")
        end

        @testset "Basic Functionality" begin
            include("basic_test.jl")
        end

        @testset "WebSocket Implementation" begin
            include("websocket_test.jl")
        end

        @testset "Element Interactions" begin
            include("element_test.jl")
        end
    finally
        cleanup()
    end
end
