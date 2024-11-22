using ChromeDevToolsLite

# Create test HTML with various checkbox scenarios
html_content = """
<!DOCTYPE html>
<html>
<body>
    <form id="test-form">
        <input type="checkbox" id="simple" name="simple">
        <label for="simple">Simple checkbox</label><br>

        <input type="checkbox" id="checked" name="checked" checked>
        <label for="checked">Pre-checked box</label><br>

        <input type="checkbox" id="disabled" name="disabled" disabled>
        <label for="disabled">Disabled checkbox</label>
    </form>
</body>
</html>
"""

# Setup
browser = Browser()
context = new_context(browser)
page = new_page(context)

# Write test HTML
test_file = "test_checkbox.html"
write(test_file, html_content)

try
    goto(page, "file://$(pwd())/$test_file")

    # Test 1: Check/uncheck simple checkbox
    println("Test 1: Basic check/uncheck...")
    checkbox = query_selector(page, "#simple")
    check(checkbox)
    @assert evaluate_handle(checkbox, "el => el.checked") "Checkbox should be checked"
    uncheck(checkbox)
    @assert !evaluate_handle(checkbox, "el => el.checked") "Checkbox should be unchecked"

    # Test 2: Pre-checked box
    println("Test 2: Pre-checked box...")
    checked_box = query_selector(page, "#checked")
    @assert evaluate_handle(checked_box, "el => el.checked") "Should start checked"
    uncheck(checked_box)
    @assert !evaluate_handle(checked_box, "el => el.checked") "Should be unchecked"

    println("✓ All checkbox tests passed!")
finally
    # Cleanup
    rm(test_file, force=true)
    close(browser)
end
