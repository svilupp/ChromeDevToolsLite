using ChromeDevToolsLite

# Start browser and navigate to test page
browser = Browser()
context = create_browser_context(browser)
page = create_page(context)

# Create a test HTML file with checkboxes
html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>Checkbox Test</title>
</head>
<body>
    <form id="preferences-form">
        <div>
            <input type="checkbox" id="notifications" name="notifications">
            <label for="notifications">Enable notifications</label>
        </div>
        <div>
            <input type="checkbox" id="newsletter" name="newsletter" checked>
            <label for="newsletter">Subscribe to newsletter</label>
        </div>
        <div>
            <input type="checkbox" id="terms" name="terms">
            <label for="terms">Accept terms</label>
        </div>
    </form>
    <div id="status"></div>

    <script>
        document.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                const status = document.getElementById('status');
                status.textContent = 'Changed: ' + checkbox.id + ' is now ' + (checkbox.checked ? 'checked' : 'unchecked');
            });
        });
    </script>
</body>
</html>
"""

test_file = joinpath(@__DIR__, "..", "test", "test_pages", "checkbox.html")
write(test_file, html_content)
goto(page, "file://" * test_file)

# Test initial state
newsletter_checked = evaluate(page, "document.querySelector('#newsletter').checked")
@assert newsletter_checked "Newsletter should be checked initially"

notifications_checked = evaluate(page, "document.querySelector('#notifications').checked")
@assert !notifications_checked "Notifications should be unchecked initially"

# Test toggling checkboxes
click(page, "#notifications")  # Check notifications
click(page, "#newsletter")     # Uncheck newsletter
click(page, "#terms")         # Check terms

# Verify changes
notifications_checked = evaluate(page, "document.querySelector('#notifications').checked")
@assert notifications_checked "Notifications should be checked after clicking"

newsletter_checked = evaluate(page, "document.querySelector('#newsletter').checked")
@assert !newsletter_checked "Newsletter should be unchecked after clicking"

terms_checked = evaluate(page, "document.querySelector('#terms').checked")
@assert terms_checked "Terms should be checked after clicking"

# Verify status message for last change
status_text = get_text(page, "#status")
@assert status_text == "Changed: terms is now checked" "Status message incorrect"

println("✓ Checkbox interaction test successful")

# Clean up
close(browser)
rm(test_file)  # Remove the test HTML file
