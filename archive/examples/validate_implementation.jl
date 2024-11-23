using ChromeDevToolsLite
using HTTP
using JSON3
using Base64
using Test

# This script validates our minimal CDP implementation against Python's chrome-remote-interface
# Requires Python and chrome-remote-interface to be installed:
# pip install chrome-remote-interface

function run_python_validation()
    python_script = """
import chrome_remote_interface
import json
import base64

def test_cdp():
    chrome = chrome_remote_interface.Chrome()
    try:
        # Get version
        version = chrome.Browser.getVersion()
        print(f"PYTHON_VERSION:{version['product']}")

        # Navigate
        chrome.Page.enable()
        chrome.Page.navigate(url='https://example.com')

        # Get title
        result = chrome.Runtime.evaluate(expression='document.title')
        title = result['result']['value']
        print(f"PYTHON_TITLE:{title}")

        # Take screenshot
        screenshot = chrome.Page.captureScreenshot()
        with open('python_screenshot.png', 'wb') as f:
            f.write(base64.b64decode(screenshot['data']))

    finally:
        chrome.close()

test_cdp()
"""

    open("validate.py", "w") do f
        write(f, python_script)
    end

    run(`python3 validate.py`)
end

println("Running validation suite...")
run_python_validation()

# Run our Julia implementation
println("\nValidating Julia implementation...")

# Connect to Chrome
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))
client = connect_chrome(target.webSocketDebuggerUrl)

try
    # 1. Browser Version
    version = send_cdp_message(client, Dict(
        "method" => "Browser.getVersion"
    ))
    julia_version = version.result.product
    println("JULIA_VERSION:$julia_version")

    # 2. Navigation
    send_cdp_message(client, Dict("method" => "Page.enable"))
    send_cdp_message(client, Dict(
        "method" => "Page.navigate",
        "params" => Dict("url" => "https://example.com")
    ))
    sleep(1)

    # 3. JavaScript Evaluation
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => "document.title",
            "returnByValue" => true
        )
    ))
    julia_title = result.result.result.value
    println("JULIA_TITLE:$julia_title")

    # 4. Screenshot
    result = send_cdp_message(client, Dict(
        "method" => "Page.captureScreenshot"
    ))
    write("julia_screenshot.png", base64decode(result.result.data))

    # Compare results
    println("\nValidation Results:")
    output = read("validate.py.out", String)

    println("1. Browser Version:")
    python_version = match(r"PYTHON_VERSION:(.*)", output).captures[1]
    println("   Match: $(python_version == julia_version)")

    println("2. Title comparison:")
    python_title = match(r"PYTHON_TITLE:(.*)", output).captures[1]
    println("   Match: $(python_title == julia_title)")

    println("3. Screenshot comparison:")
    python_size = filesize("python_screenshot.png")
    julia_size = filesize("julia_screenshot.png")
    size_diff_percent = abs(python_size - julia_size) / python_size * 100
    println("   Size difference: $(round(size_diff_percent, digits=2))%")

finally
    close(client)
    rm("validate.py", force=true)
    rm("python_screenshot.png", force=true)
    rm("julia_screenshot.png", force=true)
end
