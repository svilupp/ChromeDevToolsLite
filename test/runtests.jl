using ChromeDevToolsLite
using Test
using HTTP

include("setup_chrome.jl")
include("test_utils.jl")

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    @info "Setting up Chrome for tests..."
    @test setup_chrome()

    @testset "Basic Functionality" begin
        include("basic_test.jl")
    end

    @testset "WebSocket Implementation" begin
        include("websocket_test.jl")
    end
end
