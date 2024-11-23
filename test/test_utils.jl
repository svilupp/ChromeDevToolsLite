"""
    setup_chrome(; endpoint = ENDPOINT)

Sets up Chrome for testing. On Linux systems in CI, installs and starts Chrome if needed.
Otherwise, verifies Chrome is running on port 9222.
"""
function setup_chrome(; endpoint = ENDPOINT)
    # First check if Chrome is already running on port 9222
    @info "Checking if Chrome is already running on port 9222..."

    for _ in 1:3  # Try up to 3 times
        try
            response = HTTP.get("$endpoint/json/version", retry=false, readtimeout=10)
            @info "Chrome already running on port 9222" version=String(response.body)
            return true
        catch e
            @debug "Chrome check failed, retrying..." exception=e
            sleep(2.0)  # Wait before retry
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
        run(`wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -`)
        run(`sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'`)
        run(`sudo apt-get update`)
        run(`sudo apt-get install -y google-chrome-stable`)
        @info "Chrome installation completed"
    else
        @info "Chrome already installed"
    end

    # Kill any existing Chrome instances
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
        `google-chrome --remote-debugging-port=9222 --headless=new --disable-gpu --no-sandbox --disable-software-rasterizer`,
        stdout=devnull,
        stderr=devnull
    )
    process = run(cmd, wait=false)

    # Wait for Chrome to be ready
    sleep(5.0)  # Give Chrome more time to start
    return true
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

function setup_test()
    @debug "Setting up test environment"
    setup_chrome(; endpoint = ENDPOINT)
    sleep(2.0)  # Increased sleep time to ensure Chrome is fully ready

    # More robust browser availability check
    for _ in 1:3
        if ensure_browser_available(ENDPOINT; max_retries = 3, retry_delay = 2.0)
            client = connect_browser(ENDPOINT)
            @debug "Browser connection established"
            return client
        end
        sleep(1.0)
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
