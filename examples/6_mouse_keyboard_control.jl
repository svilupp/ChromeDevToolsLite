using ChromeDevToolsLite

println("Starting mouse and keyboard control example...")

# Connect to browser
browser = connect_browser()
page = get_page(browser)

println("\n1. Basic Mouse Control")
# Navigate to a test page
goto(page, "https://example.com")

# Move mouse to specific coordinates and click
move_mouse(page, 100, 100)
click(page)

# Perform a right-click with modifier
click(page, button="right", modifiers=["Shift"])

println("\n2. Keyboard Input")
# Type some text
type_text(page, "Hello, World!")

# Press special keys
press_key(page, "Enter")
press_key(page, "ArrowDown")

# Modifier key combinations
press_key(page, "a", modifiers=["Control"]) # Ctrl+A to select all

println("\n3. Combined Actions")
# Double-click at specific coordinates
dblclick(page, x=200, y=200)

# Get current mouse position
pos = get_mouse_position(page)
println("Current mouse position: x=$(pos.x), y=$(pos.y)")

println("\nExample completed successfully!")
close_browser(browser)
