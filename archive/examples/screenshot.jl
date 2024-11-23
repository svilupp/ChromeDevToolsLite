using ChromeDevToolsLite
using HTTP
using JSON3
using Base64

# Example assumes Chrome is already running with remote debugging enabled:
# chromium --remote-debugging-port=9222 --headless

# Get available debugging targets
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))

println("Connecting to target: ", target.title)
client = connect_chrome(target.webSocketDebuggerUrl)

# Enable Page domain
println("\nEnabling Page domain...")
send_cdp_message(client, Dict("method" => "Page.enable"))

# Example 1: Full page screenshot
println("\n1. Capturing full page screenshot...")
msg1 = Dict(
    "method" => "Page.captureScreenshot",
    "params" => Dict("format" => "png")
)
response = send_cdp_message(client, msg1)
write("full_page.png", base64decode(response.result.data))
println("Full page screenshot saved ($(filesize("full_page.png")) bytes)")

# Example 2: Viewport screenshot
println("\n2. Capturing viewport screenshot...")
msg2 = Dict(
    "method" => "Page.captureScreenshot",
    "params" => Dict(
        "format" => "png",
        "clip" => Dict(
            "x" => 0,
            "y" => 0,
            "width" => 800,
            "height" => 600,
            "scale" => 1
        )
    )
)
response = send_cdp_message(client, msg2)
write("viewport.png", base64decode(response.result.data))
println("Viewport screenshot saved ($(filesize("viewport.png")) bytes)")

# Clean up
close(client)
rm("full_page.png")
rm("viewport.png")
