using HTTP

"""
    ensure_chrome_running()

Ensures Chrome is running in debug mode on port 9222.
Returns true if Chrome was successfully started or was already running.
"""
function ensure_chrome_running()
    # First ensure Chrome is installed
    try
        run(`which google-chrome`)
    catch
        @info "Installing Chrome..."
        run(`sudo apt-get update`)
        run(`sudo apt-get install -y google-chrome-stable`)
    end

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

        # Give Chrome more time to start in CI environment
        sleep(5)  # Increased from 2 to 5 seconds

        # Verify Chrome is now running
        for _ in 1:3  # Try up to 3 times
            try
                response = HTTP.get("http://localhost:9222/json/version")
                return true
            catch
                sleep(2)
            end
        end
        return false
    end
end

export ensure_chrome_running
