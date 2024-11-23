using ChromeDevToolsLite
using HTTP
using JSON3

# Get Chrome debugging endpoint
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
ws_url = first(filter(t -> t.type == "page", targets)).webSocketDebuggerUrl

println("Connecting to: ", ws_url)

# Create client
client = connect_chrome(ws_url)

# Test basic CDP command
msg = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "document.title",
        "returnByValue" => true
    )
)

result = send_cdp_message(client, msg)
println("\nResponse:")
println(JSON3.pretty(result))

close(client)
