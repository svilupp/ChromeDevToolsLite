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

try
    # Connect to page
    page_ws_url = get_page_websocket_url()
    page_client = WSClient(page_ws_url)

    # Enable necessary domains
    send_cdp_message(page_client, "Page.enable")
    send_cdp_message(page_client, "Runtime.enable")

    # Test navigation
    urls = [
        "https://example.com",
        "https://example.org",
        "https://example.net"
    ]

    for url in urls
        println("\nNavigating to $url...")
        send_cdp_message(page_client, "Page.navigate", Dict("url" => url))

        # Wait for page load
        println("Waiting for page load...")
        for _ in 1:10
            result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
                "expression" => "document.readyState",
                "returnByValue" => true
            ))
            if result["result"]["result"]["value"] == "complete"
                println("Page loaded!")

                # Get page title
                result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
                    "expression" => "document.title",
                    "returnByValue" => true
                ))
                println("Title: $(result["result"]["result"]["value"])")
                break
            end
            sleep(0.2)
        end
    end

catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up...")
    try
        run(`pkill chrome`)
    catch
    end
end
