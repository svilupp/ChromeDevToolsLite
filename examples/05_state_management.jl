using ChromeDevToolsLite

println("Starting state management example...")
browser = Browser("http://localhost:9222")
page = nothing

try
    page = new_page(browser)
    println("\n✓ Created new page")

    # 1. Basic State Verification
    println("\n1. Testing basic state verification:")
    state = verify_page_state(browser, page)
    println("  Initial state:")
    println("  • Ready: ", state["ready"])
    println("  • URL: ", state["url"])
    println("  • Metrics: ", state["metrics"])

    # 2. Navigation with State Tracking
    println("\n2. Navigation with state verification:")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))
    println("  • Navigation initiated")

    state = verify_page_state(browser, page)
    if state !== nothing
        println("  ✓ Navigation successful:")
        println("    • Title: ", state["title"])
        println("    • URL: ", state["url"])
        println("    • Links found: ", state["metrics"]["links"])
        println("    • Forms found: ", state["metrics"]["forms"])
    else
        println("  ✗ Navigation verification failed")
    end

    # 3. Batch Element Updates
    println("\n3. Testing batch element updates:")

    # Create test form
    setup = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const form = document.createElement('form');
            form.innerHTML = `
                <input id="username" type="text">
                <input id="email" type="email">
                <input id="remember" type="checkbox">
            `;
            document.body.appendChild(form);
            return true;
        """,
        "returnByValue" => true
    ))

    # Perform batch updates
    updates = Dict(
        "#username" => "testuser",
        "#email" => "test@example.com"
    )

    println("  • Attempting batch updates...")
    result = batch_update_elements(browser, page, updates)

    println("  Update results:")
    for (selector, success) in result
        println("    • $selector: ", success ? "✓ Updated" : "✗ Failed")
    end

    # 4. Form State Verification
    println("\n4. Verifying form state:")
    verify = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                username: document.querySelector('#username')?.value,
                email: document.querySelector('#email')?.value
            })
        """,
        "returnByValue" => true
    ))

    if !haskey(verify, "error")
        data = verify["result"]["value"]
        println("  Final form state:")
        println("    • Username: ", data["username"])
        println("    • Email: ", data["email"])
    end

catch e
    println("\n✗ Error: ", e)
finally
    if page !== nothing
        close_page(browser, page)
        println("\n✓ Page closed")
    end
end
