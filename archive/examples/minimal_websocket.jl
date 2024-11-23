using ChromeDevToolsLite
using HTTP
using JSON3

# Get available Chrome targets
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
ws_url = first(filter(t -> t.type == "page", targets)).webSocketDebuggerUrl

println("Connecting to WebSocket: $ws_url")

# Create client and test connection
client = connect_chrome(ws_url)

# Send a simple CDP command
msg = Dict(
    "method" => "Browser.getVersion",
    "params" => Dict()
)

println("\nSending message...")
result = send_cdp_message(client, msg)
println("Response:")
println(JSON3.pretty(result))

# Clean up
close(client)
