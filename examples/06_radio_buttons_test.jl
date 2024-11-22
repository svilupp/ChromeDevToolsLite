using ChromeDevToolsLite

# Start browser and navigate to test page
browser = Browser()
context = create_browser_context(browser)  # Create context through CDP
page = create_page(context)
test_file = "file://$(joinpath(pwd(), "examples", "test_pages", "radio_buttons.html"))"
goto(page, test_file)

# Test initial state
initial_text = get_text(page, "#selected-value")
@assert initial_text == "No color selected" "Initial state incorrect"

# Test clicking each radio button
colors = ["red", "blue", "green"]
for color in colors
    # Click the radio button
    click(page, "#$(color)")

    # Verify the selection was updated
    selected_text = get_text(page, "#selected-value")
    expected_text = "Selected color: $(color)"
    @assert selected_text == expected_text "Radio button selection failed for $(color)"

    # Verify the radio button is checked
    is_checked = evaluate(page, """
        document.querySelector('#$(color)').checked
    """)
    @assert is_checked "Radio button $(color) not checked after clicking"
end

println("✓ Radio button interaction test successful")

# Clean up
close(browser)
