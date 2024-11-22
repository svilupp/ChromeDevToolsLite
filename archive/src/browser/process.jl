"""
Module for managing browser process and launch configuration.
"""

"""
    BrowserProcess

Represents a running browser process with its debugging endpoint and configuration options.
"""
struct BrowserProcess
    pid::Int
    endpoint::String
    options::Dict{String, Any}
end

"""
    Base.show(io::IO, process::BrowserProcess)

Custom display for BrowserProcess instances, showing the process ID and endpoint.
"""
function Base.show(io::IO, process::BrowserProcess)
    print(io, "BrowserProcess(pid=$(process.pid), endpoint=$(process.endpoint))")
end

const DEFAULT_ARGS = [
    "--disable-background-networking",
    "--enable-features=NetworkService,NetworkServiceInProcess",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows",
    "--disable-breakpad",
    "--disable-client-side-phishing-detection",
    "--disable-component-extensions-with-background-pages",
    "--disable-default-apps",
    "--disable-dev-shm-usage",
    "--disable-extensions",
    "--disable-features=TranslateUI",
    "--disable-hang-monitor",
    "--disable-ipc-flooding-protection",
    "--disable-popup-blocking",
    "--disable-prompt-on-repost",
    "--disable-renderer-backgrounding",
    "--disable-sync",
    "--force-color-profile=srgb",
    "--metrics-recording-only",
    "--no-first-run",
    "--no-default-browser-check",
    "--password-store=basic",
    "--use-mock-keychain",
    "--enable-automation",  # Added for CDP support
    "--enable-blink-features=IdleDetection",  # Added for CDP support
    "--no-sandbox",  # Added to fix permission issues
    "--disable-gpu",  # Disable GPU hardware acceleration
    "--disable-software-rasterizer",  # Disable software rasterizer
    "--disable-setuid-sandbox",  # Disable setuid sandbox (also helps with permissions)
    "--remote-debugging-port=0"  # Will be replaced with actual port
]

"""
    find_chrome() -> AbstractString

Find the Chrome/Chromium executable path.
"""
function find_chrome()
    # Prefer system chromium over snap version
    chrome_executables = [
        "/usr/bin/chromium-browser",  # System chromium
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable",
        "chromium",
        "chromium-browser",
        "google-chrome",
        "google-chrome-stable",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ]

    # Try to find Chrome in specific paths first, then PATH
    for exec in chrome_executables
        path = if startswith(exec, "/")
            isfile(exec) ? exec : nothing
        else
            try
                chomp(read(`which $exec`, String))
            catch
                nothing
            end
        end
        if !isnothing(path) && !isempty(path) && !contains(path, "snap")
            return path
        end
    end

    error("Could not find suitable Chrome/Chromium installation. Please install Chrome or Chromium.")
end

"""
    get_available_port() -> Int

Find an available port for the browser's debugging interface.
"""
function get_available_port()
    server = Sockets.listen(0)  # Let the OS choose an available port
    sockname = getsockname(server)
    port_number = Int(sockname[2])  # Port is the second element in the tuple
    close(server)
    return port_number
end

# Function to find the PID of the process listening on a given port
function find_process_id(port::Int; verbose::Bool = true)
    if Sys.isunix()
        # Use lsof on Unix-like systems (including macOS)
        cmd = `lsof -nP -iTCP -sTCP:LISTEN`
        try
            output = read(cmd, String)
            lines = split(chomp(output), '\n')
            for line in lines[2:end]  # Skip the header line
                cols = split(strip(line))
                # Expected format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (last one can split)
                if length(cols) >= 9
                    pid = parse(Int, cols[2])  # PID is the second column
                    name = cols[end]           # NAME is the last column
                    m = match(r".*:(\d+)\s*(\(LISTEN\))?", name)
                    if isnothing(m)
                        ## It's 10 columns, take penultimate
                        address = cols[end - 1]
                        m = match(r":(\d+)", address)
                    end
                    if !isnothing(m) && parse(Int, m.captures[1]) == port
                        return pid
                    end
                end
            end
        catch e
            verbose && @warn "Failed to find process ID using lsof" exception=e
            return nothing
        end
        return nothing
    elseif Sys.iswindows()
        # Windows implementation without shell pipe
        try
            # First run netstat
            netstat_output = read(`netstat -ano`, String)
            # Then filter the lines in Julia
            lines = split(netstat_output, '\n')
            port_str = ":$port"
            for line in lines
                if contains(line, port_str)
                    cols = split(strip(line))
                    if length(cols) >= 5 && cols[1] == "TCP"
                        pid = parse(Int, cols[end])
                        return pid
                    end
                end
            end
            return nothing
        catch e
            verbose && @warn "Failed to find process ID using netstat" exception=e
            return nothing
        end
    else
        verbose && @warn "Unsupported operating system for process ID retrieval"
        return nothing
    end
end

"""
    launch_browser_process(;
        headless::Bool = true,
        port::Union{Int, Nothing} = nothing,
        endpoint::Union{String, Nothing} = nothing,
        verbose::Bool = false)

Launch a new browser process with the specified options.
Or connect to an existing browser process at the given endpoint.
"""
function launch_browser_process(;
        headless::Bool = true,
        port::Union{Int, Nothing} = nothing,
        endpoint::Union{String, Nothing} = nothing,
        verbose::Bool = false)
    if !isnothing(endpoint)
        # Attempt to connect to the existing browser at the given endpoint
        verbose &&
            @info "Attempting to connect to existing browser at endpoint" endpoint=endpoint
        try
            response = HTTP.get("$endpoint/json/version")
            if response.status == 200
                verbose &&
                    @info "Connected to existing browser at endpoint" endpoint=endpoint
                pid = find_process_id(parse(Int, split(endpoint, ":")[end]))
                return BrowserProcess(
                    isnothing(pid) ? -1 : pid,
                    endpoint,
                    Dict{String, Any}("headless" => headless, "verbose" => verbose)
                )
            else
                error("Failed to connect to browser at $endpoint: HTTP $(response.status)")
            end
        catch e
            error("Failed to connect to browser at $endpoint: $e")
        end
    elseif !isnothing(port)
        # Construct the endpoint from the given port
        endpoint = "http://localhost:$port"
        verbose &&
            @info "Attempting to connect to existing browser at endpoint" endpoint=endpoint
        try
            response = HTTP.get("$endpoint/json/version")
            if response.status == 200
                verbose &&
                    @info "Connected to existing browser at endpoint" endpoint=endpoint
                pid = find_process_id(port)
                return BrowserProcess(
                    isnothing(pid) ? -1 : pid,
                    endpoint,
                    Dict{String, Any}("headless" => headless, "verbose" => verbose)
                )
            else
                # Proceed to launch a new browser if connection fails
                verbose &&
                    @warn "No existing browser at $endpoint, will launch a new browser"
            end
        catch e
            # Proceed to launch a new browser if connection fails
            verbose &&
                @warn "Failed to connect to browser at $endpoint: $e. Launching a new browser."
        end
    end

    # Proceed to launch a new browser process
    chrome_path = find_chrome()
    debug_port = isnothing(port) ? get_available_port() : port

    args = copy(DEFAULT_ARGS)
    filter!(x -> !startswith(x, "--remote-debugging-port"), args)
    push!(args, "--remote-debugging-port=$(debug_port)")

    if headless
        push!(args, "--headless=new")
    end

    # Launch browser process
    process = try
        verbose &&
            @info "Launching new browser process..." chrome_path=chrome_path args=args
        proc = run(`$chrome_path $(args)`, wait = false)
        sleep(2.0)  # Allow time for the browser to initialize
        if !process_running(proc)
            error("Browser process failed to start")
        end
        proc
    catch e
        error("Failed to launch browser process: $e")
    end

    # Get process ID
    pid = try
        if process_running(process)
            verbose && @info "Browser process started successfully" pid=process.handle
            process.handle
        else
            error("Browser process failed to start")
        end
    catch e
        error("Failed to get browser process ID: $e")
    end

    # Wait for the debugging endpoint to be ready
    endpoint = "http://localhost:$debug_port"
    max_attempts = 30
    verbose && @info "Waiting for browser to be ready at endpoint" endpoint=endpoint
    for attempt in 1:max_attempts
        try
            response = HTTP.get("$endpoint/json/version")
            if response.status == 200
                verbose && @info "Browser endpoint is ready" attempt=attempt
                return BrowserProcess(
                    pid,
                    endpoint,
                    Dict{String, Any}("headless" => headless, "verbose" => verbose)
                )
            end
        catch e
            verbose &&
                @warn "Attempt $attempt: Could not connect to browser endpoint" exception=e
            sleep(1.0)
        end
    end

    # If all attempts fail, terminate the process
    kill(process)
    error("Failed to connect to browser endpoint at $endpoint after $max_attempts attempts")
end

# Helper function to check if process is running
function process_running(p)
    try
        process_running(p.pid)
    catch
        false
    end
end

function process_running(pid::Integer)
    try
        kill(pid, 0)  # Signal 0 just checks if process exists
        return true
    catch
        return false
    end
end

"""
    kill_browser_process(process::BrowserProcess)

Terminate the browser process.
"""
function kill_browser_process(process::BrowserProcess)
    try
        run(`kill $(process.pid)`)
    catch e
        @warn "Failed to kill browser process" exception=e
    end
end