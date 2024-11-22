using ChromeDevToolsLite

# Connect to Chrome and create a new page
browser = connect_browser()
page = new_page(browser)

try
    # Navigate to a website with known content
    execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://httpbin.org/html"))

    # Wait for page load and check content
    sleep(2)

    # First check if we can get the document
    debug_result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.documentElement.outerHTML",
        "returnByValue" => true
    ))
    println("Debug - Full page content:", debug_result)

    # Find elements by selector and get their text content
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            Array.from(document.getElementsByTagName('p')).map(el => el.textContent)
        """,
        "returnByValue" => true
    ))

    println("Found paragraphs:", get(result, "value", nothing))

    # Click a button (if it exists)
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const button = document.querySelector('button');
            if (button) button.click();
        """
    ))

    # Fill a form
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const input = document.querySelector('input[type="text"]');
            if (input) {
                input.value = 'Hello World';
                input.dispatchEvent(new Event('input'));
            }
        """
    ))

    # Take a screenshot
    result = execute_cdp_method(browser, page, "Page.captureScreenshot")
    # Save screenshot to file
    using Base64
    open("screenshot.png", "w") do io
        write(io, base64decode(get(result, "data", "")))
    end
finally
    # Clean up
    close_page(browser, page)
end
