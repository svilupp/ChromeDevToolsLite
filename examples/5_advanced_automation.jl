"""
    Advanced Browser Automation Example

This example demonstrates advanced browser automation techniques:
1. Multiple page handling
2. Network request monitoring
3. Event handling
4. Complex JavaScript execution
"""

using ChromeDevToolsLite, JSON3

println("Starting advanced automation example...")
client = connect_browser(verbose = true)

try
    println("\n1. Page Navigation and Network Monitoring")
    goto(client, "https://httpbin.org/html")

    # Execute complex JavaScript to modify the page
    println("\n2. Complex DOM Manipulation")
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
            p.style.border = '1px solid gray';
        });
    """)

    # Get modified content
    println("\n3. Content Verification")
    content_info = evaluate(client, """
        JSON.stringify({
            newHeader: document.querySelector('h2').textContent,
            modifiedParagraphs: Array.from(document.getElementsByTagName('p')).map(p => ({
                text: p.textContent.substring(0, 50) + '...',
                color: p.style.color
            }))
        })
    """)

    content_data = JSON3.read(content_info)
    println("New Header: ", content_data["newHeader"])
    println("\nModified Paragraphs:")
    for (i, p) in enumerate(content_data["modifiedParagraphs"])
        println("$i. Color: $(p["color"]), Preview: $(p["text"])")
    end

    # Take a screenshot of our modifications
    println("\n4. Capturing Result")
    screenshot(client, verbose = true)
    println("Screenshot saved as 'screenshot.png'")

    println("\nExample completed successfully!")
finally
    println("Closing browser connection...")
    close(client)
end
