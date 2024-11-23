using ChromeDevToolsLite
using Logging

# Set logging level
global_logger(ConsoleLogger(stderr, Logging.Info))

@info "Starting WebSocket functionality test..."

try
    # Connect to Chrome
    @info "Connecting to Chrome..."
    client = connect_browser()
    @info "Connected successfully"

    # Navigate to example.com
    @info "Testing navigation..."
    send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => "https://www.example.com"))
    sleep(2)  # Wait for page load

    # Get page title
    @info "Testing JavaScript evaluation..."
    result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "document.title",
        "returnByValue" => true
    ))
    title = get(get(get(result, "result", Dict()), "result", Dict()), "value", "Unknown")
    @info "Page title: $title"

    # Get page dimensions
    @info "Getting page dimensions..."
    dims_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "({width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight})",
        "returnByValue" => true
    ))
    dims = get(get(get(dims_result, "result", Dict()), "result", Dict()), "value", Dict())
    @info "Page dimensions: $dims"

    # Test click simulation
    @info "Testing click simulation..."
    send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "document.querySelector('h1').click()",
        "returnByValue" => true
    ))

    @info "Test completed successfully"
    close(client)
catch e
    @error "Test failed" exception=(e, catch_backtrace())
    rethrow()
end
