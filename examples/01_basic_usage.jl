using ChromeDevToolsLite

println("Connecting to Chrome (ensure it's running with --remote-debugging-port=9222)...")
browser = Browser("http://localhost:9222")

page = nothing
try
    # Create and verify new page
    page = new_page(browser)
    println("\n✓ Created new page: $(page.id)")

    # List all pages to verify creation
    pages = get_pages(browser)
    println("\nActive browser pages:")
    for p in pages
        println("  • $(p.title) ($(p.url))")
    end

    println("\nExecuting basic CDP operations:")

    # Navigate to a website
    println("\n1. Navigation test:")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))
    if haskey(result, "error")
        println("  ✗ Navigation failed: ", result["error"])
        return
    end
    println("  ✓ Navigation initiated")

    # Verify page load using state management
    println("  • Verifying page state...")
    state = verify_page_state(browser, page)
    if state !== nothing && state["ready"]
        println("  ✓ Page loaded successfully")
        println("    • URL: ", state["url"])
        println("    • Metrics: ", state["metrics"])
    else
        println("  ⚠ Page load verification failed")
    end

    # Execute JavaScript for page information
    println("\n2. JavaScript evaluation test:")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                title: document.title,
                url: window.location.href,
                h1: document.querySelector('h1')?.textContent,
                links: Array.from(document.querySelectorAll('a')).length
            })
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("  ✗ JavaScript execution failed: ", result["error"])
    else
        data = result["result"]["value"]
        println("  ✓ Page information:")
        println("    • Title: ", data["title"])
        println("    • URL: ", data["url"])
        println("    • H1 Text: ", data["h1"])
        println("    • Link count: ", data["links"])
    end
catch e
    println("\n✗ Error: ", e)
finally
    if page !== nothing
        close_page(browser, page)
        println("\n✓ Page closed successfully")
    end
end
