using ChromeDevToolsLite

browser = launch_browser()
context = new_context(browser)
page = new_page(context)

# Navigate to different pages
goto(page, "https://example.com")
wait_for_load_state(page)

# Get page title
title = get_title(page)
println("Page title: $title")

# Get current URL
url = get_url(page)
println("Current URL: $url")

close(browser)
