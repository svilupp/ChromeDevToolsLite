using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

# Create a temporary directory for screenshots
screenshot_dir = mkpath(joinpath(pwd(), "test_screenshots"))

try
    # Navigate to our test page with multiple elements
    goto(page, "file:///home/ubuntu/ChromeDevToolsLite/test/test_pages/multiple_elements.html")

    # Test 1: Full page screenshot
    println("Test 1: Taking full page screenshot...")
    full_page_path = joinpath(screenshot_dir, "full_page.png")
    screenshot(page, full_page_path)
    @assert isfile(full_page_path) "Full page screenshot not created"

    # Test 2: Element screenshot
    println("Test 2: Taking element screenshot...")
    special_item = query_selector(page, ".item.special")
    element_path = joinpath(screenshot_dir, "special_element.png")
    screenshot(special_item, element_path)
    @assert isfile(element_path) "Element screenshot not created"

    # Test 3: Screenshot with custom clip region
    println("Test 3: Taking clipped screenshot...")
    container = query_selector(page, ".container")
    box = get_bounding_box(container)
    clipped_path = joinpath(screenshot_dir, "clipped.png")
    screenshot(page, clipped_path, Dict("clip" => box))
    @assert isfile(clipped_path) "Clipped screenshot not created"

    println("✓ All screenshot tests passed!")
finally
    # Cleanup
    close(browser)
    # Remove test screenshots
    rm(screenshot_dir, recursive=true, force=true)
end
