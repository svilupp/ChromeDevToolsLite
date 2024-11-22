using ChromeDevToolsLite

# Start browser and navigate to test page
browser = Browser()
context = create_browser_context(browser)
page = create_page(context)

# Create a test HTML file with a form
html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>Form Submission Test</title>
</head>
<body>
    <form id="registration-form">
        <div>
            <label for="username">Username:</label>
            <input type="text" id="username" name="username">
        </div>
        <div>
            <label for="email">Email:</label>
            <input type="email" id="email" name="email">
        </div>
        <div>
            <label for="agree">Agree to terms:</label>
            <input type="checkbox" id="agree" name="agree">
        </div>
        <button type="submit">Submit</button>
    </form>
    <div id="submission-result"></div>

    <script>
        document.getElementById('registration-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const form = e.target;
            const result = {
                username: form.username.value,
                email: form.email.value,
                agree: form.agree.checked
            };
            document.getElementById('submission-result').textContent =
                'Form submitted with: ' + JSON.stringify(result);
        });
    </script>
</body>
</html>
"""

test_file = joinpath(pwd(), "examples", "test_pages", "form_submission.html")
write(test_file, html_content)
goto(page, "file://$test_file")

# Fill out the form
type_text(page, "#username", "testuser123")
type_text(page, "#email", "test@example.com")
click(page, "#agree")  # Check the agreement box

# Submit the form
click(page, "button[type=\"submit\"]")

# Wait a moment for the submission to process
sleep(0.5)

# Verify form submission result
result_text = get_text(page, "#submission-result")
expected_result = """Form submitted with: {"username":"testuser123","email":"test@example.com","agree":true}"""
@assert result_text == expected_result "Form submission result doesn't match expected output"

println("✓ Form submission test successful")

# Clean up
close(browser)
rm(test_file)
