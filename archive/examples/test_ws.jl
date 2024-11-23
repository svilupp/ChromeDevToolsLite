using ChromeDevToolsLite
using HTTP
using JSON3

# Get Chrome debugging endpoint
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
ws_url = first(filter(t -> t.type == "page", targets)).webSocketDebuggerUrl

println("Connecting to: ", ws_url)

# Test connection
client = connect_chrome(ws_url)

# Send a simple CDP command
msg = Dict(
    "method" => "Browser.getVersion",
    "params" => Dict()
)

result = send_cdp_message(client, msg)
println("\nResponse:")
println(JSON3.pretty(result))

close(client)
