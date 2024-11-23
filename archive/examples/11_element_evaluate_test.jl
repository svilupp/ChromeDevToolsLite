using ChromeDevToolsLite

# Start browser and navigate to test page
browser = Browser()
context = BrowserContext(browser)
page = Page(context)

test_path = joinpath(@__DIR__, "..", "test", "test_pages", "element_evaluate.html")
goto(page, "file://$test_path")

# Test element property access
div = query_selector(page, "#test-div")
@assert evaluate_handle(div, "el => el.className") == "test-class" "Class name test failed"
@assert evaluate_handle(div, "el => el.getAttribute('data-custom')") == "test-value" "Data attribute test failed"
@assert evaluate_handle(div, "el => el.textContent") == "Test Content" "Text content test failed"

# Test checkbox state
checkbox = query_selector(page, "#test-checkbox")
@assert evaluate_handle(checkbox, "el => el.checked") == true "Checkbox state test failed"

# Test input value
input = query_selector(page, "#test-input")
@assert evaluate_handle(input, "el => el.value") == "test value" "Input value test failed"

# Test select element
select = query_selector(page, "#test-select")
@assert evaluate_handle(select, "el => el.value") == "2" "Select value test failed"
@assert evaluate_handle(select, "el => el.options[el.selectedIndex].text") == "Option 2" "Selected option text test failed"

println("All element evaluation tests passed!")

close(browser)
