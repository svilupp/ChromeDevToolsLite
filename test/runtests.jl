using ChromeDevToolsLite
using Test
using HTTP
using Logging

# Configure test logging
ENV["JULIA_DEBUG"] = "ChromeDevToolsLite"
const ENDPOINT = "http://localhost:9222"
logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)

include("test_utils.jl")

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    client = setup_test()
    include("basic_test.jl")
    include("websocket_test.jl")
    include("element_test.jl")
    include("comprehensive_test.jl")
    teardown_test(client)
    cleanup()
end
