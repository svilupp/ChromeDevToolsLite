using ChromeDevToolsLite

# Create a browser instance with a specific port
println("Launching browser...")
browser = launch_browser(headless=true, port=9223, debug=true)  # Added debug=true
println("Browser launched successfully")

println("Creating browser context...")
@time context = create_browser_context(browser)  # Added @time to measure duration
println("Browser context created successfully")

println("Creating page...")
@time page = create_page(context)  # Added @time to measure duration
println("Page created successfully")

# Create a test HTML file path
test_file = joinpath(@__DIR__, "test_pages", "selectors.html")

# Create the test HTML file
open(test_file, "w") do f
    write(f, """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Selector Test Page</title>
    </head>
    <body>
        <div id="visible">Visible Element</div>
        <div id="hidden" style="display: none;">Hidden Element</div>
        <div class="multiple">Element 1</div>
        <div class="multiple">Element 2</div>
        <div class="multiple">Element 3</div>
    </body>
    </html>
    """)
end

# Test 1: Basic selector functionality
println("\nTest 1: Testing basic selector functionality...")
println("Navigating to test file...")
@time begin
    goto(page, "file://$test_file")
    wait_for_load(page)
end
println("Navigation complete")

println("Testing selectors...")
@time begin
    element_count = count_elements(page, ".multiple")
    println("Found $element_count elements with class 'multiple'")
    @assert element_count == 3 "Expected 3 elements with class 'multiple'"

    element_count = count_elements(page, "#visible")
    println("Found $element_count elements with id 'visible'")
    @assert element_count == 1 "Expected 1 element with id 'visible'"
end
println("✓ Basic selector tests passed")

# Test 2: Visibility checks
println("\nTest 2: Testing visibility checks...")
@time begin
    visible = is_visible(page, "#visible")
    println("Visibility of #visible: $visible")
    @assert visible == true "Expected #visible to be visible"

    hidden = is_visible(page, "#hidden")
    println("Visibility of #hidden: $hidden")
    @assert hidden == false "Expected #hidden to be hidden"
end
println("✓ Visibility tests passed")

# Test 3: Text content
println("\nTest 3: Testing text content...")
@time begin
    text = get_text(page, "#visible")
    println("Text content of #visible: $text")
    @assert text == "Visible Element" "Expected correct text content"
end
println("✓ Text content tests passed")

# Test 4: Multiple elements iteration
println("\nTest 4: Testing multiple elements...")
@time begin
    elements = query_selector_all(page, ".multiple")
    println("Found $(length(elements)) multiple elements")
    expected_texts = ["Element 1", "Element 2", "Element 3"]
    for (i, element) in enumerate(elements)
        println("Debug: Element $i has nodeId: $(element.element_id)")
        text = get_text(element)
        println("Element $i text: $text")
        @assert text == expected_texts[i] "Expected correct text for multiple element $i"
    end
end
println("✓ Multiple elements tests passed")

# Cleanup
println("\nClosing browser...")
@time close(browser)
println("Browser closed")
rm(test_file)

println("\nAll selector tests passed! ✓")
