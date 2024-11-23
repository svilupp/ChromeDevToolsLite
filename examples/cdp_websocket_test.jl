using ChromeDevToolsLite
using Logging

# Set logging level
global_logger(ConsoleLogger(stderr, Logging.Info))

function run_cdp_test()
    try
        @info "Starting CDP WebSocket test..."

        # Connect to Chrome
        client = connect_browser()
        @info "Connected to Chrome successfully"

        # Enable necessary domains
        @info "Enabling Page and Runtime domains"
        send_cdp_message(client, "Page.enable", Dict{String,Any}())
        send_cdp_message(client, "Runtime.enable", Dict{String,Any}())

        # Navigate to example.com
        @info "Navigating to example.com..."
        nav_result = send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => "https://example.com"))
        @info "Navigation initiated" frameId=get(nav_result["result"], "frameId", "unknown")

        # Wait for page load
        sleep(2)

        # Get page title
        @info "Getting page title..."
        title_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
            "expression" => "document.title",
            "returnByValue" => true
        ))
        title = get(get(get(title_result, "result", Dict()), "result", Dict()), "value", "unknown")
        @info "Page title" title=title

        # Get page content
        @info "Getting page content..."
        content_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
            "expression" => "document.body.innerText",
            "returnByValue" => true
        ))
        content = get(get(get(content_result, "result", Dict()), "result", Dict()), "value", "unknown")
        @info "Page content retrieved" content_length=length(content)

        @info "CDP WebSocket test completed successfully"
        close(client)
    catch e
        @error "Test failed" exception=e
        rethrow()
    end
end

# Run the test if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_cdp_test()
end
