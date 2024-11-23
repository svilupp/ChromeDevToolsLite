using ChromeDevToolsLite

browser = launch_browser()
context = new_context(browser)
page = new_page(context)

try
    # Try to find an element with timeout
    element = wait_for_selector(page, "#non-existent", timeout=5000)
catch e
    if e isa TimeoutError
        println("Element not found within timeout period")
    elseif e isa ElementNotFoundError
        println("Element does not exist on the page")
    else
        rethrow(e)
    end
end

close(browser)
