"""
    Page Operations Example

This example demonstrates various page operations:
1. Navigation and content extraction
2. JavaScript evaluation
3. Screenshots
4. Working with page content
"""

using ChromeDevToolsLite

println("Starting page operations example...")
client = connect_browser(verbose = true)

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
    screenshot(client, verbose = true)
    println("Screenshot saved (check current directory for 'screenshot.png')")

    println("\n5. Page Information")
    page = get_page(client)
    # Get viewport information
    viewport = get_viewport(page)
    println("Current viewport: ", viewport)

    println("\n6. Multiple Pages")
    # Create a new page
    new_tab = new_page(client)
    println("Created new tab")

    # List all pages
    all_pages = get_all_pages(client)
    println("Total open pages: $(length(all_pages))")

    # Navigate new tab to a different site
    goto(new_tab, "https://example.org")
    page_info = get_page_info(new_tab)
    println("New tab info: ", page_info)

    # Customize viewport in new tab
    set_viewport(new_tab, width = 1920, height = 1080)
    println("Set viewport to 1920x1080")

    # Clean up by closing the new tab
    close(new_tab)

    println("\n7. Advanced JavaScript Evaluation")
    # Get a handle to a DOM element
    handle = evaluate_handle(client, "document.querySelector('h1')")
    println("Got handle to heading: ", handle)

    println("\nExample completed successfully!")
finally
    println("Closing browser connection...")
    close(client)
end