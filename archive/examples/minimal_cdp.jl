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

# Example 1: Browser information
println("\nExample 1: Browser version")
msg1 = Dict(
    "method" => "Browser.getVersion"
)
response1 = send_cdp_message(client, msg1)
println("Browser: ", response1.result.product)
println("Protocol version: ", response1.result.protocolVersion)

# Example 2: Enable necessary domains
println("\nExample 2: Enable domains")
for domain in ["Page", "Runtime", "DOM"]
    msg = Dict("method" => "$(domain).enable")
    send_cdp_message(client, msg)
end
println("Domains enabled")

# Example 3: Get document title
println("\nExample 3: Get document title")
msg3 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "document.title",
        "returnByValue" => true
    )
)
response3 = send_cdp_message(client, msg3)
println("Title: ", response3.result.result.value)

# Example 4: Query DOM
println("\nExample 4: Query DOM")
msg4 = Dict(
    "method" => "DOM.getDocument",
    "params" => Dict("depth" => 1)
)
response4 = send_cdp_message(client, msg4)
println("Root node: ", response4.result.root.nodeName)

# Example 5: Execute JavaScript
println("\nExample 5: Execute JavaScript")
msg5 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "({viewport: {width: window.innerWidth, height: window.innerHeight}, url: window.location.href})",
        "returnByValue" => true
    )
)
response5 = send_cdp_message(client, msg5)
println("Page info: ", response5.result.result.value)

# Clean up
close(client)
