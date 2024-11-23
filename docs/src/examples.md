# Examples

This guide showcases practical examples demonstrating ChromeDevToolsLite features. All examples can be found in the `examples/` directory.

## Basic Connection
```julia
using ChromeDevToolsLite

println("Starting basic connection example...")
client = connect_browser(verbose=true)

try
    # Basic navigation
    goto(client, "https://example.com")

    # Get page title using JavaScript
    title = evaluate(client, "document.title")
    println("Page title: $title")
finally
    close(client)
end
```

## Page Operations
```julia
# Get and display page content
html_content = content(client)
println("First 100 chars of content: ", html_content[1:min(100, length(html_content))])

# Take a screenshot
screenshot(client, verbose=true)
println("Screenshot saved (check current directory for 'screenshot.png')")
```

## Element Interactions
```julia
# Fill in form fields
evaluate(client, """
    document.querySelector('input[name="custname"]').value = 'John Doe';
    document.querySelector('input[value="medium"]').click();
    document.querySelector('input[value="bacon"]').click();
    document.querySelector('textarea[name="comments"]').value = 'Please ring doorbell twice';
""")

# Verify inputs
name = evaluate(client, "document.querySelector('input[name=\"custname\"]').value")
size = evaluate(client, "document.querySelector('input[name=\"size\"]:checked').value")
```

## Form Automation
```julia
# Complex form handling with JSON verification
form_data = evaluate(client, """
    JSON.stringify({
        name: document.querySelector('input[name="custname"]').value,
        size: document.querySelector('input[name="size"]:checked').value,
        toppings: Array.from(document.querySelectorAll('input[name="topping"]:checked'))
            .map(el => el.value)
    })
""")
```

## Advanced Automation
```julia
# Dynamic DOM manipulation
evaluate(client, """
    // Create new elements
    const newHeader = document.createElement('h2');
    newHeader.textContent = 'Dynamically Added Content';
    document.body.insertBefore(newHeader, document.body.firstChild);

    // Modify existing elements
    const paragraphs = document.getElementsByTagName('p');
    Array.from(paragraphs).forEach((p, index) => {
        p.style.color = index % 2 ? 'blue' : 'green';
        p.style.padding = '10px';
    });
""")
```
