"""
    setup_chrome(; endpoint = "http://localhost:9222")

Sets up Chrome for testing. On Linux systems in CI, installs and starts Chrome if needed.
Otherwise, verifies Chrome is running on port 9222.
"""
function setup_chrome(; endpoint = "http://localhost:9222")
    # First check if Chrome is already running on port 9222
    @info "Checking if Chrome is already running on port 9222..."
    try
        response = HTTP.get("$endpoint/json/version", retry = false, readtimeout = 5)
        @info "Chrome already running on port 9222" version=String(response.body)
        return true
    catch e
        @debug "Initial Chrome check failed" exception=e

        # Chrome is not running on port 9222
        if !Sys.islinux()
            error("""
            Chrome must be running in debug mode on port 9222.
            Please start Chrome with the following flags:
            --remote-debugging-port=9222 --headless --disable-gpu
            """)
        end

        # We're in Linux, proceed with installation if needed
        @info "Checking Chrome installation..."
        chrome_installed = try
            success(`which google-chrome`)
        catch
            false
        end

        if !chrome_installed
            @info "Chrome not found, installing..."
            run(`sudo apt-get update`)
            run(`sudo apt-get install -y google-chrome-stable`)
            @info "Chrome installation completed"
        else
            @info "Chrome already installed"
        end

        # Kill any existing Chrome instances more thoroughly
        @info "Cleaning up any existing Chrome processes..."
        try
            run(`pkill -f "google-chrome.*--remote-debugging-port"`)
            sleep(3)  # Give more time for cleanup
        catch e
            @debug "No matching Chrome processes found" exception=e
        end

        # Start Chrome in debug mode with more robust options
        @info "Starting Chrome in debug mode..."
        cmd = pipeline(
            `google-chrome --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox --disable-software-rasterizer`,
            stdout = devnull,
            stderr = devnull
        )
        process = run(cmd, wait = false)

        # More robust startup check
        max_retries = 10  # Increased retries
        retry_delay = 3   # Seconds between retries
        for attempt in 1:max_retries
            @info "Checking Chrome availability (attempt $attempt/$max_retries)..."
            try
                # First check HTTP endpoint
                response = HTTP.get(
                    "$endpoint/json/version", retry = false, readtimeout = 5)
                version_info = String(response.body)

                # Then verify WebSocket endpoint
                endpoints = HTTP.get("$endpoint/json/list", retry = false, readtimeout = 5)
                if occursin("webSocketDebuggerUrl", String(endpoints.body))
                    @info "Chrome started successfully" attempt version_info
                    return true
                else
                    @warn "Chrome started but WebSocket endpoint not ready"
                end
            catch e
                if attempt == max_retries
                    @error "Failed to start Chrome after $max_retries attempts" exception=e
                    error("Chrome failed to start properly")
                else
                    @debug "Chrome not ready yet (attempt $attempt/$max_retries)" exception=e
                    sleep(retry_delay)
                end
            end
        end

        error("Failed to start Chrome in debug mode after $max_retries attempts")
    end
end

# Global cleanup function
function cleanup()
    try
        if Sys.islinux()
            run(`pkill chrome`)
            sleep(1)  # Give time for process to terminate
        end
    catch
        # Ignore cleanup errors
    end
end