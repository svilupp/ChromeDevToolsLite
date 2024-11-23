"""
Browser domain implementation for Chrome DevTools Protocol.
Basic functionality for browser control.
"""

"""
    get_version(client::WSClient)

Get version information about the browser.
"""
function get_version(client::WSClient)
    send_cdp_message(client, "Browser.getVersion")
end

"""
    get_windows(client::WSClient)

Get list of all browser windows.
"""
function get_windows(client::WSClient)
    send_cdp_message(client, "Browser.getWindowForTarget")
end
