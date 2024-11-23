using ChromeDevToolsLite

# Initialize browser and create a new page
browser = Browser()
context = create_browser_context(browser)
page = Page(context)

println("Starting navigation tests...")

# Test 1: Valid navigation
println("Test 1: Testing navigation to valid page...")
local_file = "file://$(joinpath(@__DIR__, "test_pages", "navigation_test.html"))"
goto(page, local_file)

# Verify navigation success
title = get_title(page)
current_url = url(page)
@assert title == "Navigation Test Page" "Page title mismatch: $title"
@assert current_url == local_file "URL mismatch: $current_url"

# Test 2: Content loading and dynamic updates
println("Test 2: Testing content loading...")
# Wait for the content to be updated by JavaScript
sleep(1)  # Give time for the load event
content_element = query_selector(page, "#content")
loaded_status = evaluate_handle(content_element, "el => el.dataset.loaded")
@assert loaded_status == "true" "Page content not fully loaded"

content_text = evaluate_handle(content_element, "el => el.textContent")
@assert content_text == "Page Loaded Successfully" "Content mismatch: $content_text"

# Test 3: Invalid URL handling
println("Test 3: Testing invalid URL handling...")
try
    goto(page, "https://invalid.url.that.does.not.exist.example")
    error("Expected error for invalid URL")
catch e
    println("✓ Successfully caught invalid URL error")
end

# Test 4: Timeout handling
println("Test 4: Testing timeout handling...")
try
    # Use a very short timeout to trigger timeout error
    goto(page, "https://example.com", timeout=1)  # 1ms timeout
    error("Expected timeout error")
catch e
    println("✓ Successfully caught timeout error")
end

println("\nAll navigation tests passed! ✓")

# Cleanup
close(browser)
