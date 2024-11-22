"""
Module for managing browser process and launch configuration.
"""

using Sockets
using WebSockets
using JSON3
using HTTP

"""
    BrowserProcess

Represents a running browser process with its debugging endpoint and configuration options.
"""
struct BrowserProcess
    pid::Int
    endpoint::String
    options::Dict{String,Any}
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
        "google-chrome-stable"
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
        # Create temp files for stdout and stderr
        stdout_file = tempname()
        stderr_file = tempname()
        proc = run(pipeline(`$chrome_path $(args)`; stdout=stdout_file, stderr=stderr_file), wait=false)
        sleep(5.0)  # Increased sleep time to give browser more time to initialize
        if !process_running(proc)
            # Read and log the error output if process failed to start
            stderr_content = read(stderr_file, String)
            @error "Browser process failed to start" stderr=stderr_content
            error("Browser process failed to start: $stderr_content")
        end
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
    endpoint = "http://localhost:$debug_port"
    max_attempts = 30
    timeout = 5  # Increased timeout

    verbose && @info "Waiting for browser to be ready at $endpoint..."
    for attempt in 1:max_attempts
        try
            verbose && @info "Attempt $attempt to connect to browser endpoint"
            # Try to connect to the browser's HTTP endpoint
            response = HTTP.get("$endpoint/json/version")
            if response.status == 200
                verbose && @info "Browser endpoint ready"
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
