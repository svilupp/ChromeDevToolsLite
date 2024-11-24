"""
    setup_chrome(; endpoint = ENDPOINT)

Sets up Chrome for testing. On Linux systems in CI, installs and starts Chrome if needed.
Otherwise, verifies Chrome is running on port 9222.
"""
function setup_chrome(; endpoint = ENDPOINT)
    # First check if Chrome is already running on port 9222
    @info "Checking if Chrome is already running on port 9222..."

    # More robust Chrome process cleanup before starting
    cleanup()
    sleep(2.0)  # Give more time for cleanup

    # Check if Chrome is already running with proper verification
    for attempt in 1:5  # Increased retries
        try
            response = HTTP.get("$endpoint/json/version", retry=false, readtimeout=15)
            if response.status == 200
                version_info = JSON3.read(String(response.body))
                @info "Chrome running" version=get(version_info, "Browser", "unknown")
                return true
            end
        catch e
            @debug "Chrome check attempt $attempt failed" exception=e
            sleep(3.0)  # Increased wait time between retries
        end
    end

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
        # Create and run a temporary shell script to install Chrome
        script = """
        #!/bin/bash
        wget -q -O /tmp/chrome_key.pub https://dl-ssl.google.com/linux/linux_signing_key.pub
        sudo apt-key add /tmp/chrome_key.pub
        sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
        sudo apt-get update
        sudo apt-get install -y google-chrome-stable
        """
        write("/tmp/install_chrome.sh", script)
        chmod("/tmp/install_chrome.sh", 0o755)
        run(`/tmp/install_chrome.sh`)
        rm("/tmp/install_chrome.sh")
        @info "Chrome installation completed"
    else
        @info "Chrome already installed"
    end

    # Enhanced Chrome process management
    @info "Cleaning up any existing Chrome processes..."
    try
        run(`pkill -f "google-chrome"`)
        run(`pkill -f "chromium"`)
        sleep(5.0)  # Increased cleanup time
    catch e
        @debug "Chrome process cleanup" exception=e
    end

    # Start Chrome with enhanced stability options
    @info "Starting Chrome in debug mode..."
    cmd = pipeline(
        `google-chrome --remote-debugging-port=9222 --headless=new --disable-gpu --no-sandbox --disable-dev-shm-usage --disable-software-rasterizer --no-first-run --no-default-browser-check --disable-extensions`,
        stdout=devnull,
        stderr=devnull
    )
    process = run(cmd, wait=false)

    # More thorough Chrome readiness check
    for _ in 1:10  # Increased number of attempts
        try
            response = HTTP.get("$endpoint/json/version", retry=false, readtimeout=5)
            if response.status == 200
                @info "Chrome started successfully"
                return true
            end
        catch
            sleep(1.0)
        end
    end

    error("Failed to start Chrome after multiple attempts")
end

# Global cleanup function with enhanced process management
function cleanup()
    try
        if Sys.islinux()
            # Kill all Chrome-related processes
            run(`pkill -f "google-chrome"`)
            run(`pkill -f "chromium"`)
            # Clean up any remaining Chrome temporary files
            run(`rm -rf /tmp/.com.google.Chrome*`)
            run(`rm -rf /tmp/.org.chromium*`)
            sleep(3.0)  # Increased cleanup time
        end
    catch e
        @debug "Cleanup error (non-critical)" exception=e
    end
end

function setup_test()
    @debug "Setting up test environment"

    # Multiple setup attempts with proper cleanup between tries
    for attempt in 1:3
        try
            cleanup()
            setup_chrome(; endpoint = ENDPOINT)
            sleep(3.0)  # Increased wait time for Chrome stability

            if ensure_browser_available(ENDPOINT; max_retries = 5, retry_delay = 2.0)
                client = connect_browser(ENDPOINT)
                @debug "Browser connection established on attempt $attempt"
                return client
            end
        catch e
            @warn "Setup attempt $attempt failed" exception=e
            cleanup()
            sleep(2.0)
        end
    end

    error("Failed to establish browser connection after multiple attempts")
end

function teardown_test(client)
    if client !== nothing
        close(client)
    end
    @debug "Tearing down test environment"
    sleep(0.5)  # Give Chrome time to clean up
end
