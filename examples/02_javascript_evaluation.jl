using ChromeDevToolsLite

println("Starting advanced JavaScript evaluation example...")
browser = Browser("http://localhost:9222")
page = nothing

try
    page = new_page(browser)
    println("\n✓ Created new page")

    # Navigate to a website with error handling
    println("\n1. Navigation and page load:")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))
    if haskey(result, "error")
        println("  ✗ Navigation failed: ", result["error"])
        return
    end
    println("  ✓ Navigation initiated")

    # Wait for page load
    println("  • Waiting for page load...")
    start_time = time()
    timeout = 5
    load_success = false

    while (time() - start_time) < timeout
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
            "expression" => "document.readyState === 'complete'",
            "returnByValue" => true
        ))
        if !haskey(result, "error") && result["result"]["value"]
            load_success = true
            break
        end
        sleep(0.1)
    end
    println(load_success ? "  ✓ Page loaded successfully" : "  ⚠ Page load timeout")

    println("\nExecuting JavaScript operations:")

    # 1. Basic page information
    println("\n1. Getting page information:")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                title: document.title,
                url: window.location.href,
                viewport: {
                    width: window.innerWidth,
                    height: window.innerHeight
                },
                userAgent: navigator.userAgent
            })
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("  ✗ Failed: ", result["error"])
    else
        data = result["result"]["value"]
        println("  ✓ Basic Information:")
        println("    • Title: ", data["title"])
        println("    • URL: ", data["url"])
        println("    • Viewport: $(data["viewport"]["width"])x$(data["viewport"]["height"])")
    end

    # 2. DOM Analysis
    println("\n2. Analyzing DOM structure:")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                headings: {
                    h1: document.querySelectorAll('h1').length,
                    h2: document.querySelectorAll('h2').length,
                    h3: document.querySelectorAll('h3').length
                },
                links: Array.from(document.querySelectorAll('a')).map(a => ({
                    text: a.textContent,
                    href: a.href
                })),
                images: document.querySelectorAll('img').length,
                textContent: document.body.textContent.trim().substring(0, 100) + '...'
            })
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("  ✗ Failed: ", result["error"])
    else
        data = result["result"]["value"]
        println("  ✓ DOM Analysis:")
        println("    • Headings: H1 ($(data["headings"]["h1"])), H2 ($(data["headings"]["h2"])), H3 ($(data["headings"]["h3"]))")
        println("    • Links found: $(length(data["links"]))")
        println("    • Images: $(data["images"])")
        println("    • Preview: $(data["textContent"])")
    end

    # 3. DOM Manipulation
    println("\n3. Testing DOM manipulation:")
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            (function() {
                // Create a new element
                const div = document.createElement('div');
                div.id = 'test-div';
                div.textContent = 'Added by ChromeDevToolsLite';
                div.style.backgroundColor = 'yellow';
                div.style.padding = '10px';
                document.body.appendChild(div);

                // Modify existing content
                const h1 = document.querySelector('h1');
                if (h1) {
                    const originalText = h1.textContent;
                    h1.textContent = 'Modified: ' + originalText;
                }

                return {
                    success: true,
                    modifications: {
                        newElement: '#' + div.id,
                        modifiedH1: h1 ? true : false
                    }
                };
            })()
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("  ✗ DOM manipulation failed: ", result["error"])
    else
        data = result["result"]["value"]
        println("  ✓ DOM Manipulation Results:")
        println("    • Added element: ", data["modifications"]["newElement"])
        println("    • Modified H1: ", data["modifications"]["modifiedH1"] ? "Yes" : "No")
    end

catch e
    println("\n✗ Error: $e")
finally
    if page !== nothing
        close_page(browser, page)
        println("\n✓ Page closed")
    end
end
