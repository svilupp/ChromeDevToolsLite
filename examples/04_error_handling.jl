using ChromeDevToolsLite

println("Demonstrating CDP error handling patterns...")
browser = Browser("http://localhost:9222")
page = nothing

try
    # 1. Page Creation Error Handling
    println("\n1. Testing page management:")
    try
        page = new_page(browser)
        println("  ✓ Page created successfully")
    catch e
        println("  ✗ Failed to create page: $e")
        rethrow(e)
    end

    # 2. Navigation Error Handling
    println("\n2. Testing navigation error handling:")

    # a. Invalid URL
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://nonexistent.example.com"
    ))
    println("  • Invalid URL test: ", haskey(result, "error") ? "✓ Caught" : "✗ Missed")

    # b. Page Load Timeout
    println("  • Testing page load timeout:")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))

    # Wait for page load with timeout
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
    println("  • Page load timeout test: ", load_success ? "✓ Loaded" : "✓ Timeout caught")

    # 3. JavaScript Execution Error Handling
    println("\n3. Testing JavaScript error scenarios:")

    # a. Syntax Error
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "{ invalid: javascript: syntax",
        "returnByValue" => true
    ))
    println("  • Syntax error test: ", haskey(result, "error") ? "✓ Caught" : "✗ Missed")

    # b. Reference Error
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "nonExistentFunction()",
        "returnByValue" => true
    ))
    println("  • Reference error test: ", haskey(result, "error") ? "✓ Caught" : "✗ Missed")

    # c. Type Error
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "null.someProperty",
        "returnByValue" => true
    ))
    println("  • Type error test: ", haskey(result, "error") ? "✓ Caught" : "✗ Missed")

    # 4. Testing HTTP-specific errors
    println("\n4. Testing HTTP-specific scenarios:")

    # a. Invalid CDP Method
    try
        execute_cdp_method(browser, page, "InvalidMethod", Dict())
        println("  • Invalid method test: ✗ Should have thrown error")
    catch e
        println("  • Invalid method test: ✓ Expected error caught")
    end

    # b. Malformed Parameters
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "invalid_param" => "value"
    ))
    println("  • Malformed parameters test: ", haskey(result, "error") ? "✓ Caught" : "✗ Missed")

    # c. Connection Error Simulation
    try
        bad_browser = Browser("http://localhost:1234")  # Invalid port
        new_page(bad_browser)
        println("  • Connection error test: ✗ Should have thrown error")
    catch e
        println("  • Connection error test: ✓ Expected error caught")
    end

    # 5. Recovery After Error
    println("\n5. Testing recovery after errors:")
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))
    if !haskey(result, "error")
        println("  ✓ Successfully recovered with new navigation")
    end

catch e
    println("\n✗ Fatal error: $e")
finally
    if page !== nothing
        try
            close_page(browser, page)
            println("\n✓ Page closed successfully")
        catch e
            println("\n✗ Error during cleanup: $e")
        end
    end
end
