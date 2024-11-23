using ChromeDevToolsLite
using Test

include("test_utils.jl")

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    @info "Setting up Chrome for tests..."
    @test ensure_chrome_running()

    @testset "Basic Functionality" begin
        include("basic_test.jl")
    end

    @testset "WebSocket Implementation" begin
        include("websocket_test.jl")
    end
end
