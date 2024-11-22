using ChromeDevToolsLite

# Create test HTML with various error scenarios
html_content = """
<!DOCTYPE html>
<html>
<body>
    <div id="existing">Existing Element</div>
    <button id="errorButton" onclick="throw new Error('Custom Error')">Error Button</button>
    <form id="testForm">
        <input type="text" id="input" required />
        <button type="submit">Submit</button>
    </form>
</body>
</html>
"""

# Setup
browser = Browser()
context = new_context(browser)
page = new_page(context)

# Write test HTML
test_file = "test_errors.html"
write(test_file, html_content)

try
    println("Running error handling tests...")

    # Test 1: ElementNotFoundError
    println("Test 1: ElementNotFoundError handling")
    try
        element = query_selector(page, "#nonexistent")
        click(element)
    catch e
        @assert e isa ElementNotFoundError "Should throw ElementNotFoundError"
    end

    # Test 2: NavigationError
    println("Test 2: NavigationError handling")
    try
        goto(page, "https://nonexistent.example.com")
    catch e
        @assert e isa NavigationError "Should throw NavigationError"
    end

    # Test 3: EvaluationError
    println("Test 3: EvaluationError handling")
    goto(page, "file://$(pwd())/$test_file")
    try
        evaluate(page, "nonexistentFunction()")
    catch e
        @assert e isa EvaluationError "Should throw EvaluationError"
    end

    # Test 4: TimeoutError with element waiting
    println("Test 4: TimeoutError handling")
    try
        wait_for_selector(page, "#willNeverAppear", timeout=1000)
    catch e
        @assert e isa TimeoutError "Should throw TimeoutError"
    end

    println("✓ All error handling tests completed!")
finally
    # Cleanup
    rm(test_file, force=true)
    close(browser)
end
