#!/usr/bin/env julia

# Script to launch Chrome with remote debugging enabled
# Usage: julia launch_chrome.jl

using HTTP
using JSON3

# Kill any existing Chrome instances
try run(`pkill chromium`) catch end
sleep(1)

# Launch Chrome with remote debugging enabled
println("Starting Chrome in headless mode with remote debugging...")
chrome_proc = run(`chromium --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)

# Wait for Chrome to be ready
println("Waiting for Chrome DevTools endpoint...")
max_retries = 10
for i in 1:max_retries
    try
        response = HTTP.get("http://localhost:9222/json/version")
        if response.status == 200
            version_info = JSON3.read(response.body)
            println("\nChrome DevTools is ready!")
            println("Browser: $(version_info.Browser)")
            println("Protocol-Version: $(version_info["Protocol-Version"])")
            println("DevTools endpoint: http://localhost:9222")
            break
        end
    catch
        if i == max_retries
            error("Failed to start Chrome after $max_retries attempts")
        end
        sleep(1)
        print(".")
    end
end

println("\nPress Ctrl+C to stop Chrome")
