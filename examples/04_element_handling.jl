using ChromeDevToolsLite

browser = launch_browser()
context = new_context(browser)
page = new_page(context)

goto(page, "https://example.com")

# Find multiple elements
elements = query_selector_all(page, ".item")
for element in elements
    # Get text content
    text = get_text(element)
    println("Element text: $text")

    # Check visibility
    if is_visible(element)
        println("Element is visible")
    end

    # Get attributes
    class_attr = get_attribute(element, "class")
    println("Class attribute: $class_attr")
end

close(browser)
