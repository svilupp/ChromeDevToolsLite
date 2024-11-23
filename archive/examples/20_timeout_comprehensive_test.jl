using ChromeDevToolsLite

# Create test HTML with delayed content
html_content = """
<!DOCTYPE html>
<html>
<head>
    <script>
    function addDelayedElement() {
        setTimeout(() => {
            const div = document.createElement('div');
            div.id = 'delayed';
            div.textContent = 'Delayed Content';
            document.body.appendChild(div);
        }, 2000);
    }
    </script>
</head>
<body onload="addDelayedElement()">
    <button id="clickMe">Click Me</button>
    <input type="text" id="typeHere" />
    <div id="immediate">Immediate Content</div>
</body>
</html>
"""

# Setup
browser = Browser()
context = new_context(browser)
page = new_page(context)

# Write test HTML
test_file = joinpath(@__DIR__, "..", "test", "test_pages", "timeout_test.html")
write(test_file, html_content)

try
    println("Running timeout tests...")

    # Test 1: wait_for_selector with successful timeout
    println("Test 1: wait_for_selector with adequate timeout")
    goto(page, "file://" * test_file)
    element = wait_for_selector(page, "#delayed", timeout=3000)
    @assert element !== nothing "Element should be found within timeout"

    # Test 2: wait_for_selector with timeout error
    println("Test 2: wait_for_selector with timeout error")
    try
        wait_for_selector(page, "#nonexistent", timeout=1000)
        error("Should have timed out")
    catch e
        @assert e isa TimeoutError "Should throw TimeoutError"
    end

    # Test 3: click with timeout
    println("Test 3: click with timeout")
    click(page, "#clickMe", Dict("timeout" => 1000))

    # Test 4: type_text with timeout
    println("Test 4: type_text with timeout")
    type_text(page, "#typeHere", "Test Text", Dict("timeout" => 1000))

    # Test 5: evaluate with timeout
    println("Test 5: evaluate with timeout")
    try
        evaluate(page, "new Promise(resolve => setTimeout(resolve, 2000))",
                Dict("timeout" => 1000))
        error("Should have timed out")
    catch e
        @assert e isa TimeoutError "Should throw TimeoutError"
    end

    println("✓ All timeout tests completed!")
finally
    # Cleanup
    rm(test_file, force=true)
    close(browser)
end
