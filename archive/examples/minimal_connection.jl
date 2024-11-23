using ChromeDevToolsLite
using HTTP
using JSON3

# Example assumes Chrome is already running with remote debugging enabled:
# chromium --remote-debugging-port=9222 --headless

# Get available debugging targets
println("Getting Chrome DevTools targets...")
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)

# Find first available page target
target = first(filter(t -> t.type == "page", targets))
ws_url = target.webSocketDebuggerUrl

println("Connecting to target: ", target.title)
client = connect_chrome(ws_url)

# Send a simple command to verify connection
message = Dict(
    "id" => 1,
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "document.title",
        "returnByValue" => true
    )
)

response = send_cdp_message(client, message)
println("Page title: ", response.result.result.value)

# Clean up
close(client)
