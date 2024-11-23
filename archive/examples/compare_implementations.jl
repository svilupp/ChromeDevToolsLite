# Compare Julia ChromeDevToolsLite with Python chrome-remote-interface implementation
using ChromeDevToolsLite
using HTTP
using JSON3
using Base64

function compare_screenshots(file1, file2)
    # Compare file sizes
    size1 = filesize(file1)
    size2 = filesize(file2)
    size_diff_percent = abs(size1 - size2) / max(size1, size2) * 100
    println("Screenshot size difference: $(round(size_diff_percent, digits=2))%")
end

println("Starting Julia implementation...")

# Connect to Chrome
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))
client = connect_chrome(target.webSocketDebuggerUrl)

try
    # 1. Test Browser Version
    println("\nJulia: Testing Browser.getVersion...")
    version = send_cdp_message(client, Dict(
        "method" => "Browser.getVersion"
    ))
    println("Julia Browser: ", version.result.product)

    # 2. Test Navigation
    println("\nJulia: Testing navigation...")
    send_cdp_message(client, Dict("method" => "Page.enable"))
    nav_result = send_cdp_message(client, Dict(
        "method" => "Page.navigate",
        "params" => Dict("url" => "https://example.com")
    ))
    sleep(1)  # Brief pause for page load

    # 3. Test JavaScript Evaluation
    println("\nJulia: Testing JavaScript evaluation...")
    js_result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => "document.title",
            "returnByValue" => true
        )
    ))
    julia_title = js_result.result.result.value
    println("Julia title: $julia_title")

    # 4. Test Screenshot
    println("\nJulia: Testing screenshot...")
    screenshot = send_cdp_message(client, Dict(
        "method" => "Page.captureScreenshot"
    ))
    write("julia_screenshot.png", base64decode(screenshot.result.data))

    # Run Python implementation
    println("\nRunning Python implementation...")
    run(`python3 examples/validate_with_python.py`)

    # Compare results
    println("\nComparing implementations:")
    println("Title match: $(julia_title == "Example Domain" ? "✓" : "✗")")
    compare_screenshots("julia_screenshot.png", "cdp_screenshot.png")

finally
    println("\nCleaning up...")
    close(client)
    try
        rm("julia_screenshot.png", force=true)
        rm("cdp_screenshot.png", force=true)
    catch
    end
end
