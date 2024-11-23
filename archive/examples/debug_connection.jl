using HTTP, JSON3

# Kill any existing Chrome processes
try
    run(`pkill -f chromium`)
    sleep(1)
catch
end

# Start Chrome in debugging mode
println("Starting Chrome in debugging mode...")
run(`chromium --remote-debugging-port=9222 --headless --no-sandbox`, wait=false)
sleep(2)  # Wait for browser to start

println("Checking Chrome DevTools endpoint...")
try
    # Try to get the version info
    response = HTTP.get("http://localhost:9222/json/version")
    println("Version info response status: ", response.status)
    debug_info = JSON3.read(response.body)
    println("Debug info: ", debug_info)

    # Try to list available pages
    targets = HTTP.get("http://localhost:9222/json/list")
    println("\nAvailable targets: ", String(targets.body))
catch e
    println("Error accessing Chrome DevTools: ", e)
end

# Cleanup
println("\nCleaning up...")
try
    run(`pkill -f chromium`)
catch
end
