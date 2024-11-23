using HTTP
using JSON
include("../src/websocket.jl")

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(1)

println("Launching Chrome...")
chrome_proc = run(`google-chrome --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)
sleep(2)

try
    println("\nGetting WebSocket URL...")
    ws_url = get_websocket_url()
    println("WebSocket URL: ", ws_url)

    println("\nCreating CDP client...")
    client = WSClient(ws_url)

    println("\nTesting Browser.getVersion...")
    response = send_cdp_message(client, "Browser.getVersion")
    println("Version: ", JSON.json(response, 2))

    println("\nTesting Page.enable...")
    response = send_cdp_message(client, "Page.enable")
    println("Page.enable: ", JSON.json(response, 2))

    println("\nTesting Page.navigate...")
    response = send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))
    println("Navigation: ", JSON.json(response, 2))

catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up Chrome process...")
    try
        run(`pkill chrome`)
    catch
    end
end
