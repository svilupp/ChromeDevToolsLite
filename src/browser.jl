using HTTP.WebSockets
using HTTP
using JSON3
using URIs

"""
    connect_browser(endpoint::String="http://localhost:9222") -> Browser

Connect to an existing Chrome instance at the given debugging endpoint.
Returns a Browser instance with an active WebSocket connection.
"""
function connect_browser(endpoint::String="http://localhost:9222")
    try
        println("Debug: Attempting to connect to Chrome debugging endpoint: $endpoint")
        # Get list of available pages
        println("Debug: Fetching page list...")
        response = HTTP.get("$endpoint/json/list")
        println("Debug: Got response with status $(response.status)")
        pages = JSON3.read(response.body)
        println("Debug: Found $(length(pages)) pages")

        # Find first available page or create one if none exists
        page = nothing
        for p in pages
            if p.type == "page"  # Accept any page type, including chrome:// URLs
                println("Debug: Selected page with URL: $(p.url)")
                page = p
                break
            end
        end

        if page === nothing
            error("No suitable page found")
        end

        ws_url = page.webSocketDebuggerUrl
        @debug "WebSocket URL obtained:" ws_url

        browser_ref = Ref{Union{Browser,Nothing}}(nothing)

        # Start WebSocket connection
        println("Debug: Attempting WebSocket connection to: $ws_url")
        task = @async begin
            try
                HTTP.WebSockets.open(ws_url) do ws
                    println("Debug: WebSocket connection established")
                    browser = Browser(ws)
                    browser_ref[] = browser

                    while !eof(ws.io)
                        data = WebSockets.receive(ws)
                        if !isempty(data)
                            try
                                msg = JSON3.read(String(data), Dict)
                                println("Debug: Received message: $(JSON3.write(msg))")

                                # Handle response messages
                                if haskey(msg, "id")
                                    id = msg["id"]
                                    if haskey(browser.responses, id)
                                        put!(browser.responses[id], msg)
                                    end
                                else
                                    # Handle event messages
                                    put!(browser.messages, msg)
                                end
                            catch e
                                println("Debug: Failed to process message: ", e)
                            end
                        end
                    end
                    println("Debug: WebSocket connection closed normally")
                end
            catch e
                println("Debug: WebSocket error: ", e)
                rethrow(e)
            end
        end

        # Wait for connection with timeout
        println("Debug: Waiting for WebSocket connection...")
        timeout = 5  # Reduced timeout for faster feedback
        start_time = time()
        while browser_ref[] === nothing && (time() - start_time) < timeout
            sleep(0.1)
            print(".")  # Visual progress indicator
        end
        println()  # New line after progress dots

        if browser_ref[] === nothing
            error("Failed to establish WebSocket connection within $timeout seconds")
        end

        println("Debug: Browser connection established successfully")
        return browser_ref[]
    catch e
        error("Failed to connect to Chrome: $(sprint(showerror, e))")
    end
end

"""
    create_page(browser::Browser) -> Page

Create a new page and return it with an attached session.
"""
function create_page(browser::Browser)
    target = send_cdp_message(browser, "Target.createTarget", CDPParams.create_params(url="about:blank"))
    target_id = get(target, "targetId", "")

    session = send_cdp_message(browser, "Target.attachToTarget", CDPParams.create_params(
        targetId=target_id,
        flatten=true
    ))
    session_id = get(session, "sessionId", "")

    # In CDP, frame_id is the same as target_id for the main frame
    return Page(browser, target_id, target_id, session_id, target_id)
end
