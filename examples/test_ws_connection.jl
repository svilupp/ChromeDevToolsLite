using ChromeDevToolsLite
using Logging

ENV["JULIA_DEBUG"] = "ChromeDevToolsLite"

println("Starting WebSocket test...")

try
    println("Connecting to Chrome...")
    client = connect_browser()
    println("Connected!")

    println("Testing navigation...")
    println("Navigating to example.com...")
    nav_result = send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => "https://example.com"))
    @debug "Navigation result" nav_result

    println("Getting page title...")
    result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}("expression" => "document.title"))
    if haskey(result, "result") && haskey(result["result"], "result")
        println("Page title: ", get(result["result"]["result"], "value", "Unknown"))
    else
        @debug "Unexpected result structure" result
        println("Page title: Unknown (failed to parse result)")
    end

    println("Test completed successfully")
    close(client)
catch e
    println("Error during test: ", e)
    @error "Test failed" exception=e
    rethrow()
end
