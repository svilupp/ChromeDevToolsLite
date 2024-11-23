using ChromeDevToolsLite

# Connect to Chrome
client = connect_chrome(get_ws_url())
println("Connected to Chrome")

# Create a test page with mixed content
println("\nCreating test page...")
goto(client, "about:blank")
evaluate(client, """
    document.body.innerHTML = `
        <div id="content">
            <h1>Content Retrieval Demo</h1>
            <div class="section">
                <h2>Section 1</h2>
                <p>This is the first paragraph.</p>
            </div>
            <div class="section">
                <h2>Section 2</h2>
                <p>This is the second paragraph.</p>
            </div>
        </div>
    `;
""")

# Get full page content
println("\nRetrieving full page content:")
html = content(client)
println("Page content length: ", length(html))

# Get specific element text
println("\nRetrieving specific elements:")
h1_text = get_text(client, "h1")
println("H1 text: ", h1_text)

# Get multiple elements
sections = evaluate(client, """
    Array.from(document.querySelectorAll('.section h2'))
        .map(el => el.textContent)
        .join(', ')
""")
println("Section headings: ", sections)

# Clean up
close(client)
println("\nConnection closed.")
