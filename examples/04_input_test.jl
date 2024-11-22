using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

# Navigate to our test input page
goto(page, "file:///home/ubuntu/ChromeDevToolsLite/examples/test_pages/input.html")

# Test type_text with various inputs
println("Testing type_text with regular text...")
type_text(page, "#test-input", "Hello World")
value = get_value(page, "#test-input")
@assert value == "Hello World" "type_text failed: Expected 'Hello World', got '$value'"

# Verify that events were triggered
display_value = get_text(page, "#input-value")
@assert contains(display_value, "Hello World") && contains(display_value, "changed") "Events not triggered properly"

println("Testing type_text with special characters...")
type_text(page, "#test-input", "Hello 🌍!")
value = get_value(page, "#test-input")
@assert value == "Hello 🌍!" "type_text failed with special characters"

println("All input tests passed!")

# Cleanup
close(page)
close(context)
close(browser)
