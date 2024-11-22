using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

# Navigate to our test page
test_page = joinpath(@__DIR__, "..", "test", "test_pages", "multiple_elements.html")
goto(page, "file://" * test_page)

# Test 1: Get all items
println("Test 1: Selecting all items...")
all_items = query_selector_all(page, ".item")
@assert length(all_items) == 5 "Expected 5 items, got $(length(all_items))"

# Test 2: Check visibility status
println("Test 2: Checking visibility...")
visible_count = count(is_visible.(all_items))
@assert visible_count == 4 "Expected 4 visible items, got $visible_count"

# Test 3: Get specific attributes
println("Test 3: Checking attributes...")
for item in all_items
    testid = get_attribute(item, "data-testid")
    text = get_text(item)
    println("Item $testid: $text")
end

# Test 4: Find items with multiple classes
println("Test 4: Finding items with multiple classes...")
special_items = query_selector_all(page, ".item.special")
@assert length(special_items) == 1 "Expected 1 special item, got $(length(special_items))"

println("✓ All query_selector_all tests passed!")

# Cleanup
close(page)
close(browser)
