using HTTP

"""
    ensure_chrome_running()

Ensures Chrome is running in debug mode on port 9222.
Returns true if Chrome was successfully started or was already running.
"""
function ensure_chrome_running()
    try
        # Check if Chrome is already running by attempting to connect
        response = HTTP.get("http://localhost:9222/json/version")
        return true
    catch
        # Start Chrome in debug mode
        try
            run(`pkill chrome`)
            sleep(1)
        catch
            # Chrome wasn't running, which is fine
        end

        # Start Chrome in headless debug mode
        cmd = pipeline(`google-chrome --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, stdout=devnull, stderr=devnull)
        process = run(cmd, wait=false)
        sleep(2)  # Give Chrome time to start

        # Verify Chrome is now running
        try
            response = HTTP.get("http://localhost:9222/json/version")
            return true
        catch
            return false
        end
    end
end

export ensure_chrome_running
