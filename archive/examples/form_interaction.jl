using ChromeDevToolsLite

# Connect to browser
browser = connect_browser("http://localhost:9222")

# Navigate to a form page (using example.com/form for illustration)
js = """
    const page = await browser.pages()[0];
    await page.goto("https://example.com/form");
    return page;
"""
page = evaluate(browser, js)

# Find and fill form elements
username_input = query_selector(page, "#username")
type_text(username_input, "testuser")

password_input = query_selector(page, "#password")
type_text(password_input, "password123")

# Submit form
submit_button = query_selector(page, "button[type='submit']")
click(submit_button)

# Verify successful submission
success_message = query_selector(page, ".success-message")
if !isnothing(success_message)
    println("Form submitted successfully: ", get_text(success_message))
end
