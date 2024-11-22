using ChromeDevToolsLite

# Start browser
browser = Browser()

# Test 1: Create and verify multiple contexts
println("Test 1: Creating multiple contexts...")
context1 = new_context(browser)
context2 = new_context(browser)
all_contexts = contexts(browser)
@assert length(all_contexts) >= 2 "Expected at least 2 contexts"

# Test 2: Create and verify pages in different contexts
println("Test 2: Creating pages in different contexts...")
page1 = new_page(context1)
page2 = new_page(context1)
page3 = new_page(context2)

# Verify pages in context1
context1_pages = pages(context1)
@assert length(context1_pages) == 2 "Expected 2 pages in context1"

# Verify pages in context2
context2_pages = pages(context2)
@assert length(context2_pages) == 1 "Expected 1 page in context2"

# Test 3: Navigate pages in different contexts independently
println("Test 3: Testing context isolation...")
goto(page1, "https://example.com")
goto(page3, "https://google.com")

# Test 4: Context cleanup
println("Test 4: Testing context cleanup...")
close_context(context2)
remaining_contexts = contexts(browser)
@assert length(remaining_contexts) == 1 "Expected 1 context after cleanup"

println("✓ All browser context tests passed!")

# Cleanup
close(browser)
