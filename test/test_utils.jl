using HTTP

"""
    ensure_chrome_running()

Checks if Chrome is running in debug mode on port 9222.
Returns true if Chrome is responding on the debug port.
"""
function ensure_chrome_running()
    try
        response = HTTP.get("http://localhost:9222/json/version")
        return true
    catch
        return false
    end
end

export ensure_chrome_running
