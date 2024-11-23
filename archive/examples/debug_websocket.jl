using HTTP
using JSON

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(1)

# Start Chrome with minimal flags
run(`google-chrome --remote-debugging-port=9222 --headless=new`)
sleep(2)

println("\nFetching available endpoints...")
response = HTTP.get("http://localhost:9222/json/version")
println("Response status: ", response.status)
println("Response body: ", String(response.body))

# Try WebSocket connection
println("\nAttempting WebSocket connection...")
ws_url = JSON.parse(String(response.body))["webSocketDebuggerUrl"]
println("WebSocket URL: ", ws_url)

HTTP.WebSockets.open(ws_url) do ws
    println("WebSocket connected!")

    # Send a simple CDP command
    msg = Dict("id" => 1, "method" => "Browser.getVersion")
    println("\nSending message: ", JSON.json(msg))
    write(ws, JSON.json(msg))

    response = readavailable(ws)
    println("\nReceived response: ", String(response))
end

println("\nTest completed successfully!")
