using HTTP

"""
    setup_chrome()

Sets up Chrome for testing. On Linux systems in CI, installs and starts Chrome if needed.
Otherwise, verifies Chrome is running on port 9222.
"""
function setup_chrome()
    # First check if Chrome is already running on port 9222
    try
        @info "Checking if Chrome is already running on port 9222..."
        response = HTTP.get("http://localhost:9222/json/version")
        @info "Chrome already running on port 9222" version=String(response.body)
        return true
    catch e
        @info "Chrome not running on port 9222" exception=e

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

        # Kill any existing Chrome instances
        try
            @info "Cleaning up any existing Chrome processes..."
            run(`pkill chrome`)
            sleep(2)  # Increased sleep time
        catch
            @info "No existing Chrome processes found"
        end

        # Start Chrome in debug mode
        @info "Starting Chrome in debug mode..."
        cmd = pipeline(`google-chrome --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, stdout=devnull, stderr=devnull)
        process = run(cmd, wait=false)

        # Increased retries and wait time
        max_retries = 5  # Increased from 2
        for attempt in 1:max_retries
            @info "Waiting for Chrome to start (attempt $attempt/$max_retries)..."
            sleep(3)  # Increased from 2
            try
                response = HTTP.get("http://localhost:9222/json/version")
                version_info = String(response.body)
                @info "Chrome started successfully" attempt version_info
                return true
            catch e
                if attempt == max_retries
                    @error "Failed to start Chrome after $max_retries attempts" exception=e
                else
                    @warn "Chrome not ready yet (attempt $attempt/$max_retries)" exception=e
                end
            end
        end

        error("Failed to start Chrome in debug mode after $max_retries attempts")
    end
end

export setup_chrome
