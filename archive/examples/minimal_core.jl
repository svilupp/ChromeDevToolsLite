using ChromeDevToolsLite
using HTTP
using JSON3
using Base64

# Connect to Chrome's DevTools Protocol
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))
client = connect_chrome(target.webSocketDebuggerUrl)

try
    # Basic CDP operations demonstration

    # 1. Get browser version
    version = send_cdp_message(client, Dict(
        "method" => "Browser.getVersion"
    ))
    println("Browser: ", version.result.product)

    # 2. Navigate to page
    send_cdp_message(client, Dict("method" => "Page.enable"))
    send_cdp_message(client, Dict(
        "method" => "Page.navigate",
        "params" => Dict("url" => "https://example.com")
    ))
    sleep(1)  # Simple pause for page load

    # 3. Evaluate JavaScript
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => "document.title",
            "returnByValue" => true
        )
    ))
    println("Page title: ", result.result.result.value)

    # 4. Take screenshot
    screenshot = send_cdp_message(client, Dict(
        "method" => "Page.captureScreenshot"
    ))
    write("minimal_example.png", base64decode(screenshot.result.data))
    println("Screenshot saved as minimal_example.png")

finally
    close(client)
    rm("minimal_example.png", force=true)
end
