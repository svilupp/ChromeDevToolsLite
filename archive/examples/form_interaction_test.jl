using ChromeDevToolsLite

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(0.5)

println("Launching Chrome...")
chrome_proc = run(`google-chrome --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)

# Wait for Chrome to be ready
println("Waiting for Chrome to be ready...")
for _ in 1:10
    if check_endpoint()
        println("Chrome is ready!")
        break
    end
    sleep(0.2)
end

# Create a simple HTML form for testing
html_content = """
<!DOCTYPE html>
<html>
<body>
    <form id="testForm">
        <input type="text" id="name" placeholder="Enter name">
        <input type="checkbox" id="agree" name="agree">
        <button type="submit" id="submit">Submit</button>
    </form>
</body>
</html>
"""

open("test_form.html", "w") do io
    write(io, html_content)
end

try
    # Connect to page
    page_ws_url = get_page_websocket_url()
    page_client = WSClient(page_ws_url)

    # Enable necessary domains
    send_cdp_message(page_client, "Page.enable")
    send_cdp_message(page_client, "Runtime.enable")

    # Navigate to local file
    println("\nNavigating to test form...")
    file_path = joinpath(pwd(), "test_form.html")
    send_cdp_message(page_client, "Page.navigate", Dict("url" => "file://$file_path"))

    # Wait for page load with verification
    println("Waiting for page load...")
    for _ in 1:10
        result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
            "expression" => "document.readyState",
            "returnByValue" => true
        ))
        if result["result"]["result"]["value"] == "complete"
            println("Page loaded!")
            break
        end
        sleep(0.2)
    end

    # Type into input
    println("Typing into name field...")
    result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
        "expression" => """
            const input = document.querySelector('#name');
            input.value = 'John Doe';
            input.dispatchEvent(new Event('input'));
            input.value;  // Return the value
        """,
        "returnByValue" => true
    ))
    println("Set name to: ", result["result"]["result"]["value"])

    # Check checkbox
    println("Checking checkbox...")
    result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
        "expression" => """
            const checkbox = document.querySelector('#agree');
            checkbox.checked = true;
            checkbox.dispatchEvent(new Event('change'));
            checkbox.checked;  // Return the state
        """,
        "returnByValue" => true
    ))
    println("Checkbox checked: ", result["result"]["result"]["value"])

    # Verify values
    println("\nVerifying form values...")
    result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                name: document.querySelector('#name').value,
                agreed: document.querySelector('#agree').checked
            })
        """,
        "returnByValue" => true
    ))

    values = result["result"]["result"]["value"]
    println("Final values:")
    println("Name: $(values["name"])")
    println("Agreed: $(values["agreed"])")

catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up...")
    rm("test_form.html", force=true)
    try
        run(`pkill chrome`)
    catch
    end
end
