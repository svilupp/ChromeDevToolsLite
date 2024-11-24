"""
    Form Automation Example

This example demonstrates complex form automation:
1. Working with different input types
2. File upload simulation
3. Dynamic form handling
4. Form submission
"""

using ChromeDevToolsLite, JSON3

println("Starting form automation example...")
client = connect_browser(verbose = true)

try
    # Navigate to a complex form
    println("\n1. Navigation")
    goto(client, "https://httpbin.org/forms/post")

    println("\n2. Complex Form Automation")

    # Fill multiple form fields using a single JavaScript execution
    evaluate(client,
        """
    // Fill text inputs
    document.querySelector('input[name="custname"]').value = 'Jane Smith';
    document.querySelector('textarea[name="comments"]').value = 'Delivery after 6 PM\\nCall on arrival';

    // Handle radio buttons
    document.querySelector('input[value="large"]').click();

    // Handle multiple checkboxes
    ['bacon', 'cheese', 'mushroom', 'onion'].forEach(topping => {
        document.querySelector(`input[value="\${topping}"]`).click();
    });
""")

    # Verify form state
    println("\n3. Form State Verification")

    # Get all form values in one go
    form_data = evaluate(
        client, """
    JSON.stringify({
        name: document.querySelector('input[name="custname"]').value,
        size: document.querySelector('input[name="size"]:checked').value,
        toppings: Array.from(document.querySelectorAll('input[name="topping"]:checked'))
            .map(el => el.value),
        instructions: document.querySelector('textarea[name="comments"]').value
    })
""")
    form_data = JSON3.read(form_data)

    println("Form Data:")
    println("- Customer: ", form_data["name"])
    println("- Size: ", form_data["size"])
    println("- Toppings: ", form_data["toppings"])
    println("- Instructions: ", form_data["instructions"])

    # Submit form
    println("\n4. Form Submission")
    evaluate(client, """
        document.querySelector('form').submit();
    """)

    # Wait for submission to complete
    sleep(1)

    # Verify we're on a new page
    current_url = evaluate(client, "window.location.href")
    println("Form submitted successfully. New URL: $current_url")

    println("\nExample completed successfully!")
finally
    println("Closing browser connection...")
    close(client)
end
