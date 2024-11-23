"""
    get_ws_url() -> String

Get WebSocket URL for the first available page target.
"""
function get_ws_url()
    # Get the list of available targets
    response = HTTP.get("http://localhost:9222/json")
    targets = JSON3.read(String(response.body))

    # Find the first page type target
    for target in targets
        if target.type == "page"
            return target.webSocketDebuggerUrl
        end
    end

    error("No available page targets found")
end
