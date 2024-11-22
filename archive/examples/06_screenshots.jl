using ChromeDevToolsLite

browser = launch_browser()
context = new_context(browser)
page = new_page(context)

goto(page, "https://example.com")

# Take full page screenshot
screenshot(page, "full_page.png")

# Take screenshot of specific element
element = query_selector(page, ".header")
screenshot(element, "header.png")

close(browser)
