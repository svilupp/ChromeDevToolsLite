"""
    Page Operations Example

This example demonstrates various page operations:
1. Navigation and content extraction
2. JavaScript evaluation
3. Screenshots
4. Working with page content
"""

using ChromeDevToolsLite

function main()
    println("Starting page operations example...")
    client = connect_browser(verbose=true)

    try
        # Basic navigation
        println("\n1. Basic Navigation")
        goto(client, "https://example.com")

        # Get and display page content
        println("\n2. Page Content")
        html_content = content(client)
        println("First 100 chars of content: ", html_content[1:min(100, length(html_content))])

        # JavaScript evaluation
        println("\n3. JavaScript Evaluation")
        title = evaluate(client, "document.title")
        println("Page title: $title")

        # Get all paragraph text
        paragraphs = evaluate(client, """
            Array.from(document.getElementsByTagName('p'))
                .map(p => p.textContent)
                .toString()
        """)
        println("Found paragraphs: ", paragraphs)

        # Take a screenshot
        println("\n4. Screenshot")
        screenshot(client, verbose=true)
        println("Screenshot saved (check current directory for 'screenshot.png')")

        println("\nExample completed successfully!")
    finally
        println("Closing browser connection...")
        close(client)
    end
end

# Run the example
main()
