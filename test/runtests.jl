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

# Ensure Chrome is running before tests
@testset "ChromeDevToolsLite.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ChromeDevToolsLite)
    end
    client = setup_test()
    include("utils.jl")
    include("types.jl")
    include("basic_test.jl")
    include("websocket_test.jl")
    include("element_test.jl")
    include("comprehensive_test.jl")
    include("page_test.jl")
    include("input_test.jl")
    teardown_test(client)
    cleanup()
end
