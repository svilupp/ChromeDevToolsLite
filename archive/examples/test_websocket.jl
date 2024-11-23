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
    println("\nChecking endpoint...")
    if !check_endpoint()
        error("Chrome DevTools endpoint not accessible")
    end
    println("Endpoint accessible!")

    println("\nGetting WebSocket URL...")
    ws_url = get_websocket_url()
    println("WebSocket URL: ", ws_url)

    println("\nCreating CDP client...")
    client = WSClient(ws_url)

    println("\nTesting Browser.getVersion method...")
    response = send_cdp_message(client, "Browser.getVersion")
    println("Response: ", JSON.json(response, 2))

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
