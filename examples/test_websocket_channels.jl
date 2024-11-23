using ChromeDevToolsLite
using Logging

# Set logging level for better visibility
global_logger(ConsoleLogger(stderr, Logging.Info))

function test_websocket_channels()
    @info "Starting WebSocket channels test..."

    try
        # Test 1: Connect and get browser version
        @info "Test 1: Connect and get browser version"
        client = connect_browser()
        version_result = send_cdp_message(client, "Browser.getVersion", Dict{String,Any}())
        if haskey(version_result, "result")
            @info "Browser version" product=get(version_result["result"], "product", "unknown")
        end

        # Test 2: Navigate to page
        @info "Test 2: Navigate to page"
        nav_result = send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => "https://example.com"))
        if haskey(nav_result, "result")
            @info "Navigation successful" frameId=get(nav_result["result"], "frameId", "unknown")
        end
        sleep(2)  # Wait for page load

        # Test 3: Evaluate JavaScript
        @info "Test 3: Evaluate JavaScript"
        eval_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
            "expression" => "document.title",
            "returnByValue" => true
        ))
        if haskey(eval_result, "result") && haskey(eval_result["result"], "result")
            @info "Page title" title=get(eval_result["result"]["result"], "value", "unknown")
        end

        @info "Tests completed successfully"
        close(client)
    catch e
        @error "Test failed" exception=e
        rethrow()
    end
end

# Run the test if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    test_websocket_channels()
end
