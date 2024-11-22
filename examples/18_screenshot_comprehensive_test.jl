using ChromeDevToolsLite

# Create a simple HTML file with various elements to screenshot
html_content = """
<!DOCTYPE html>
<html>
<head>
    <style>
        .box { width: 100px; height: 100px; background: blue; margin: 20px; }
        .container { border: 1px solid black; padding: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Screenshot Test Page</h1>
        <div class="box" id="box1"></div>
        <div class="box" id="box2"></div>
    </div>
</body>
</html>
"""

# Setup
browser = Browser()
context = new_context(browser)
page = new_page(context)

# Write test HTML to a temporary file
test_file = joinpath(@__DIR__, "..", "test", "test_pages", "screenshot_test.html")
write(test_file, html_content)

try
    # Test 1: Full page screenshot
    println("Test 1: Taking full page screenshot...")
    goto(page, "file://" * test_file)
    screenshot(page, "full_page.png")
    @assert isfile("full_page.png") "Full page screenshot should exist"

    # Test 2: Element screenshot
    println("Test 2: Taking element screenshot...")
    box = query_selector(page, "#box1")
    screenshot(box, "element.png")
    @assert isfile("element.png") "Element screenshot should exist"

    # Test 3: Screenshot with clip region
    println("Test 3: Taking clipped screenshot...")
    container = query_selector(page, ".container")
    box = get_bounding_box(container)
    screenshot(page, "clipped.png", Dict("clip" => box))
    @assert isfile("clipped.png") "Clipped screenshot should exist"

    println("✓ All screenshot tests passed!")
finally
    # Cleanup
    rm(test_file, force=true)
    rm("full_page.png", force=true)
    rm("element.png", force=true)
    rm("clipped.png", force=true)
    close(browser)
end
