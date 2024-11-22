using ChromeDevToolsLite

# Connect to Chrome and create a new page
browser = connect_browser()
page = new_page(browser)

try
    # Navigate to a form page
    execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://httpbin.org/forms/post"
    ))

    # Wait for load since we can't use events
    sleep(1)

    # Fill out the form using JavaScript
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            // Fill custname
            document.querySelector('input[name="custname"]').value = 'John Doe';

            // Select a pizza size (large)
            document.querySelector('input[value="large"]').checked = true;

            // Select toppings
            document.querySelector('input[value="bacon"]').checked = true;
            document.querySelector('input[value="cheese"]').checked = true;

            // Select delivery time
            document.querySelector('select[name="delivery"]').value = '1800';

            // Add instructions
            document.querySelector('textarea[name="comments"]').value = 'Please ring the doorbell';

            // Dispatch events to ensure form state is updated
            ['custname', 'comments'].forEach(name => {
                document.querySelector(`[name="${name}"]`).dispatchEvent(new Event('input'));
            });
            ['size', 'topping', 'delivery'].forEach(name => {
                document.querySelector(`[name="${name}"]`).dispatchEvent(new Event('change'));
            });
        """
    ))

    # Submit the form
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            document.querySelector('form').submit();
        """
    ))

    # Wait for submission
    sleep(1)

    # Get the response content
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.body.textContent",
        "returnByValue" => true
    ))

    println("Form submission result:", result.result.value)
finally
    close_page(browser, page)
end
