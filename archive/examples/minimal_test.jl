using ChromeDevToolsLite
using HTTP
using JSON3

# Get available targets
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))
ws_url = target.webSocketDebuggerUrl

println("Connecting to: ", ws_url)

# Test connection
client = connect_chrome(ws_url)

# Test basic message
msg = Dict(
    "method" => "Browser.getVersion",
    "params" => Dict()
)

println("\nSending message...")
result = send_cdp_message(client, msg)
println("Response:")
println(JSON3.pretty(result))

close(client)
