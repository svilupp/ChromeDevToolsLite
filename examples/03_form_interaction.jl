using ChromeDevToolsLite

println("Starting form interaction example...")
browser = Browser("http://localhost:9222")
page = nothing

try
    page = new_page(browser)
    println("\n✓ Created new page")

    # Navigate to form page
    println("\n1. Navigating to form page...")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://httpbin.org/forms/post"
    ))
    if haskey(result, "error")
        error("Navigation failed: $(result["error"])")
    end
    println("  ✓ Navigation initiated")

    # Wait for page load
    println("  • Waiting for page load...")
    sleep(1)
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.readyState === 'complete'",
        "returnByValue" => true
    ))
    if !haskey(result, "error") && result["result"]["value"]
        println("  ✓ Page loaded successfully")
    else
        println("  ⚠ Page load status unclear")
    end

    # Verify form exists
    println("\n2. Verifying form elements...")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const elements = {
                form: !!document.querySelector('form'),
                custname: !!document.querySelector('input[name="custname"]'),
                size: !!document.querySelector('input[name="size"]'),
                toppings: !!document.querySelector('input[name="topping"]'),
                delivery: !!document.querySelector('select[name="delivery"]')
            };
            elements;
        """,
        "returnByValue" => true
    ))

    if !all(values(result["result"]["value"]))
        error("Form verification failed: Some elements are missing")
    end
    println("  ✓ All form elements present")

    # Fill out the form using JavaScript
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
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
        """,
        "returnByValue" => true
    ))

    println("\n3. Validating form data...")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                name: document.querySelector('input[name="custname"]').value,
                size: document.querySelector('input[name="size"]:checked').value,
                toppings: Array.from(document.querySelectorAll('input[name="topping"]:checked')).map(el => el.value),
                time: document.querySelector('select[name="delivery"]').value
            })
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        error("Form validation failed: $(result["error"])")
    end

    data = result["result"]["value"]
    println("  ✓ Form data verified:")
    println("    • Name: $(data["name"])")
    println("    • Size: $(data["size"])")
    println("    • Toppings: $(join(data["toppings"], ", "))")
    println("    • Delivery Time: $(data["time"])")

    println("\n4. Submitting form...")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const form = document.querySelector('form');
            const submitButton = form.querySelector('button[type="submit"]');
            if (submitButton) {
                submitButton.click();
                return { success: true, message: "Form submitted" };
            }
            return { success: false, message: "Submit button not found" };
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("  ✗ Form submission failed: $(result["error"])")
    else
        data = result["result"]["value"]
        println(data["success"] ? "  ✓ $(data["message"])" : "  ✗ $(data["message"])")
    end
finally
    page !== nothing && close_page(browser, page)
end
