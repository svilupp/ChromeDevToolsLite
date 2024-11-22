using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

try
    # Get the absolute path to our test page
    test_page_path = joinpath(dirname(@__FILE__), "test_pages", "form_submission.html")
    test_page_url = "file://" * test_page_path

    @info "Starting form submission test..."
    goto(page, test_page_url)
    wait_for_load(page)

    # Fill out form fields
    type_text(page, "#username", "testuser")
    type_text(page, "#password", "testpass")
    click(page, "#remember-me")

    # Test initial visibility
    @assert !is_visible(page, "#success-message") "Success message should be hidden initially"

    # Submit form and verify
    @assert submit_form(page, "#login-form") "Form submission should succeed"
    sleep(0.5) # Wait for any animations

    # Verify submission effects
    @assert is_visible(page, "#success-message") "Success message should be visible after submission"
    @assert get_text(page, "#success-message") == "Login successful!" "Success message text mismatch"

    @info "✓ Form submission test successful"
finally
    # Cleanup
    close(page)
    close(browser)
end
