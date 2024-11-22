using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

# Navigate to our test form
goto(page, "file:///home/ubuntu/ChromeDevToolsLite/examples/test_pages/form.html")

# Test type_text
println("Testing type_text...")
type_text(page, "#name", "John Doe")
value = get_value(page, "#name")
@assert value == "John Doe" "type_text failed: Expected 'John Doe', got '$value'"

# Test select_option
println("Testing select_option...")
select_option(page, "#color", "blue")
value = get_value(page, "#color")
@assert value == "blue" "select_option failed: Expected 'blue', got '$value'"

# Test click
println("Testing click...")
click(page, "button[type='submit']")

# Verify form submission result
sleep(1)  # Wait for the result to appear
result_text = get_text(page, "#result")
@assert contains(result_text, "John Doe") && contains(result_text, "blue") "Form submission verification failed"

println("All page interaction tests passed!")

# Cleanup
close(page)
close(browser)
