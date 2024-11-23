using ChromeDevToolsLite
using HTTP
using JSON3

println("Starting Chrome DevTools test...")

# Kill any existing Chrome processes (ignore errors)
try
    run(`pkill -f chromium`)
    sleep(1)
catch
end

# Start browser process
println("Starting Chrome in debugging mode...")
run(`chromium-browser --remote-debugging-port=9222 --headless --no-sandbox --disable-gpu`, wait=false)
sleep(2)  # Wait for browser to start

try
    println("Connecting to Chrome DevTools...")
    browser = connect_browser()
    println("Connected successfully!")

    # Test basic CDP message
    println("Testing CDP message...")
    result = send_cdp_message(browser, "Browser.getVersion", Dict())
    println("Browser info:")
    println("  Product: Chrome")
    println("  Version: ", isempty(result) ? "unknown" : split(result["product"], "/")[2])
    println("  Protocol: ", get(result, "protocolVersion", "unknown"))
catch e
    println("Error: ", e)
    println(stacktrace(catch_backtrace()))
finally
    println("Cleaning up...")
    try
        run(`pkill -f chromium`)
    catch
    end
end
