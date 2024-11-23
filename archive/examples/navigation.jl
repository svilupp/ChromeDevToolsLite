using ChromeDevToolsLite
using HTTP
using JSON3

# Example assumes Chrome is already running with remote debugging enabled:
# chromium --remote-debugging-port=9222 --headless

# Get available debugging targets
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))

println("Connecting to target: ", target.title)
client = connect_chrome(target.webSocketDebuggerUrl)

# Enable required domains
println("\nEnabling required domains...")
for domain in ["Page", "Runtime"]
    send_cdp_message(client, Dict("method" => "$(domain).enable"))
end

# Example 1: Navigate to example.com
println("\nExample 1: Navigate to example.com...")
nav_msg = Dict(
    "method" => "Page.navigate",
    "params" => Dict("url" => "https://example.com")
)
response = send_cdp_message(client, nav_msg)
println("Navigation started with id: ", response.result.loaderId)

# Get current URL
url_msg = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "window.location.href",
        "returnByValue" => true
    )
)
response = send_cdp_message(client, url_msg)
println("Current URL: ", response.result.result.value)

# Example 2: Navigate to another page
println("\nExample 2: Navigate to example.org...")
nav_msg = Dict(
    "method" => "Page.navigate",
    "params" => Dict("url" => "https://example.org")
)
send_cdp_message(client, nav_msg)

# Get page title
title_msg = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "document.title",
        "returnByValue" => true
    )
)
response = send_cdp_message(client, title_msg)
println("Page title: ", response.result.result.value)

# Clean up
close(client)
