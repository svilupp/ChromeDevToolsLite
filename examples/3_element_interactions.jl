"""
    Element Interactions Example

This example demonstrates:
1. Finding elements on the page
2. Interacting with form elements
3. Extracting element properties
"""

using ChromeDevToolsLite

println("Starting element interactions example...")
client = connect_browser(verbose = true)

try
    # Navigate to a page with form elements
    println("\n1. Navigation")
    goto(client, "https://httpbin.org/forms/post")

    # Find and interact with form elements
    println("\n2. Form Interactions")

    # Fill in the customer name field
    evaluate(client, """
        document.querySelector('input[name="custname"]').value = 'John Doe'
    """)

    # Select a pizza size
    evaluate(client, """
        document.querySelector('input[value="medium"]').click()
    """)

    # Check toppings
    evaluate(client, """
        document.querySelector('input[value="bacon"]').click();
        document.querySelector('input[value="cheese"]').click();
    """)

    # Add a delivery instruction
    evaluate(
        client, """
    document.querySelector('textarea[name="comments"]').value = 'Please ring doorbell twice'
""")

    # Verify our inputs
    println("\n3. Verifying Inputs")
    page = get_page(client)
    # Get detailed element information for the form inputs
    name_input = get_element_info(page, "input[name=\"custname\"]")
    println("Customer Name Input: ", name_input)
    name = evaluate(client, "document.querySelector('input[name=\"custname\"]').value")
    println("Customer Name Value: $name")

    size_input = get_element_info(page, "input[name=\"size\"]")
    println("Size Input: ", size_input)
    size = evaluate(client, "document.querySelector('input[name=\"size\"]:checked').value")
    println("Pizza Size: $size")

    topping_inputs = query_selector_all(page, "input[name=\"topping\"]:checked")
    println("Topping Elements: ", topping_inputs)
    toppings = evaluate(client, """
        Array.from(document.querySelectorAll('input[name="topping"]:checked'))
            .map(el => el.value)
            .join(', ')
    """)
    println("Selected Toppings: $toppings")

    comment_input = get_element_info(page, "textarea[name=\"comments\"]")
    println("Comment Input: ", comment_input)
    instructions = evaluate(
        client, "document.querySelector('textarea[name=\"comments\"]').value")
    println("Delivery Instructions: $instructions")

    println("\nExample completed successfully!")
finally
    println("Closing browser connection...")
    close(client)
end