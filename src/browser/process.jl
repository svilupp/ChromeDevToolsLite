"""
Module for managing browser process and launch configuration.
"""

using Sockets, WebSockets, JSON3

"""
    BrowserProcess

Represents a running browser process with its debugging endpoint and configuration options.
"""
struct BrowserProcess
    pid::Int
    endpoint::AbstractString
    options::AbstractDict{AbstractString,<:Any}
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
    "--remote-debugging-port=0",  # Will be replaced with actual port
]

"""
    find_chrome() -> AbstractString

Find the Chrome/Chromium executable path.
"""
function find_chrome()
    # Common paths for Chrome/Chromium
    chrome_executables = [
        "chromium",
        "chromium-browser",
        "google-chrome",
        "google-chrome-stable",
        "google-chrome-unstable",
        "google-chrome-beta"
    ]

    # Try to find Chrome in PATH
    for exec in chrome_executables
        path = try
            chomp(read(`which $exec`, String))
        catch
            continue
        end
        if !isempty(path)
            return path
        end
    end

    error("Could not find Chrome/Chromium installation. Please install Chrome or Chromium.")
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

"""
    launch_browser_process(;headless::Bool=true, port::Union{Int,Nothing}=nothing, debug::Bool=false) -> BrowserProcess

Launch a new browser process with the specified options.
"""
function launch_browser_process(;headless::Bool=true, port::Union{Int,Nothing}=nothing, debug::Bool=false, verbose::Bool=false)
    chrome_path = find_chrome()
    debug_port = isnothing(port) ? get_available_port() : port

    args = copy(DEFAULT_ARGS)
    filter!(x -> !startswith(x, "--remote-debugging-port"), args)  # Remove any existing port args
    push!(args, "--remote-debugging-port=$(debug_port)")

    if headless
        push!(args, "--headless=new")
    end

    # Launch browser process with more detailed logging
    process = try
        verbose && @info "Launching browser process..." chrome_path args
        proc = run(pipeline(`$chrome_path $(args)`; stdout=devnull, stderr=devnull), wait=false)
        sleep(2.0)  # Give the browser process time to initialize
        proc
    catch e
        error("Failed to launch browser process: $e")
    end

    # Get process ID with better error handling
    pid = try
        if Base.process_running(process)
            verbose && @info "Browser process started successfully" pid=process.handle
            process.handle
        else
            error("Browser process failed to start")
        end
    catch e
        error("Failed to get browser process ID: $e")
    end

    # Wait for the debugging port with better error handling
    endpoint = "ws://localhost:$debug_port"
    max_attempts = 30
    timeout = 5  # Increased timeout

    verbose && @info "Waiting for browser to be ready at $endpoint..."
    for attempt in 1:max_attempts
        try
            verbose && @info "Attempt $attempt to connect to browser endpoint"
            client = WebSocket(endpoint)
            if isopen(client)
                verbose && @info "Browser endpoint ready"
                close(client)
                return BrowserProcess(
                    pid,
                    endpoint,
                    Dict{String,Any}("headless" => headless, "verbose" => verbose)
                )
            end
        catch e
            verbose && @warn "Connection attempt failed" attempt=attempt exception=e
            if attempt == max_attempts
                kill(process)
                error("Failed to connect after $max_attempts attempts: $e")
            end
            sleep(1.0)  # Increased sleep time
        end
    end

    kill(process)
    error("Failed to connect to browser")
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

export BrowserProcess, launch_browser_process, kill_browser_process
