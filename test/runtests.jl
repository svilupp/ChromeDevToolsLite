using ChromeDevToolsLite
using Test
using HTTP

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
        # Try to set up Chrome with retries
        local setup_success = false
        local setup_error = nothing

        for attempt in 1:3
            try
                setup_success = setup_chrome()
                break
            catch e
                setup_error = e
                @warn "Chrome setup attempt $attempt failed" exception=e
                sleep(2)
            end
        end

        # Test Chrome setup
        if !setup_success
            @test_logs (:error, "Chrome setup failed after 3 attempts") @test false
        else
            @testset "Basic Functionality" begin
                include("basic_test.jl")
            end

            @testset "WebSocket Implementation" begin
                include("websocket_test.jl")
            end
        end
    finally
        cleanup()
    end
end
