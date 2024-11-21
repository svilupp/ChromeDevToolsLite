# Package Technical Specification

This package implements basic commands for the Chrome DevTools Protocol (CDP) in Julia.

It is inspired by Python's Playwright: [https://github.com/microsoft/playwright-python](https://github.com/microsoft/playwright-python)

## Overview

The goal is to provide a simple, function-oriented API for automating web browser interactions. The package focuses on:

- Reading the browser state (pages, contexts).
- Opening and closing pages.
- Navigating to URLs.
- Querying the DOM (by text, attribute, tag, etc.).
- Verifying the number of elements found and their visibility.
- Evaluating JavaScript expressions.
- Interacting with elements (click, type, move, etc.).
- Taking screenshots of pages.
- Accessing the page source code.
- **Implementing simple-to-use timeout functionality for operations.**

## Core Types

### `Browser`

Represents a browser instance.

- **Functions**:
  - `launch_browser(headless::Bool=true) -> Browser`: Launches a new browser instance.
  - `close_browser(browser::Browser)`: Closes the browser instance.
  - `contexts(browser::Browser) -> Vector{BrowserContext}`: Retrieves browser contexts.
  - `new_context(browser::Browser) -> BrowserContext`: Creates a new browser context.

### `BrowserContext`

Isolates a set of pages within a browser.

- **Functions**:
  - `new_page(context::BrowserContext) -> Page`: Creates a new page in the context.
  - `pages(context::BrowserContext) -> Vector{Page}`: Lists all pages in the context.
  - `close_context(context::BrowserContext)`: Closes the browser context.

### `Page`

Represents a single tab or page in the browser.

- **Functions**:
  - `goto(page::Page, url::String; options=Dict())`: Navigates to the specified URL. Supports `timeout` in options.
  - `evaluate(page::Page, expression::String) -> Any`: Evaluates JavaScript in the page context.
  - `wait_for_selector(page::Page, selector::String; timeout::Int=30000) -> ElementHandle`: Waits for an element matching selector with a simple timeout.
  - `query_selector(page::Page, selector::String) -> Union{ElementHandle, Nothing}`: Returns the first matching element.
  - `query_selector_all(page::Page, selector::String) -> Vector{ElementHandle}`: Returns all matching elements.
  - `click(page::Page, selector::String; options=Dict())`: Clicks an element matching selector. Supports `timeout` in options.
  - `type_text(page::Page, selector::String, text::String; options=Dict())`: Types text into an element. Supports `timeout` in options.
  - `screenshot(page::Page; options=Dict()) -> String`: Takes a screenshot, returns the image data.
  - `content(page::Page) -> String`: Gets the HTML content of the page.
  - `close_page(page::Page)`: Closes the page.

### `ElementHandle`

Represents a handle to a DOM element.

- **Functions**:
  - `click(element::ElementHandle; options=Dict())`: Clicks the element. Supports `timeout` in options.
  - `type_text(element::ElementHandle, text::String; options=Dict())`: Types text into the element. Supports `timeout` in options.
  - `check(element::ElementHandle; options=Dict())`: Checks the element. Supports `timeout` in options.
  - `uncheck(element::ElementHandle; options=Dict())`: Unchecks the element. Supports `timeout` in options.
  - `select_option(element::ElementHandle, value::String; options=Dict())`: Selects an option from the element. Supports `timeout` in options.
  - `is_visible(element::ElementHandle) -> Bool`: Checks if the element is visible.
  - `get_text(element::ElementHandle) -> String`: Retrieves the text content.
  - `get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}`: Gets an attribute value.
  - `evaluate_handle(element::ElementHandle, expression::String) -> Any`: Evaluates JS in the context of the element.

## Simplified Timeout Functionality

The package provides simple-to-use timeout functionality across various operations. By specifying the `timeout` parameter or including it in the `options` dictionary, users can control how long the function should wait before timing out.

- **Consistent Interface**: All relevant functions accept a `timeout` parameter or option.
- **Defaults**: Functions have sensible default timeouts, e.g., `timeout::Int=30000` (30 seconds).
- **Customization**: Users can override timeouts as needed for specific operations.

## API Functions

### Browser Functions

```julia
launch_browser(; headless::Bool=true) -> Browser
close_browser(browser::Browser)
contexts(browser::Browser) -> Vector{BrowserContext}
new_context(browser::Browser) -> BrowserContext
```

### BrowserContext Functions

```julia
new_page(context::BrowserContext) -> Page
pages(context::BrowserContext) -> Vector{Page}
close_context(context::BrowserContext)
```

### Page Functions

```julia
goto(page::Page, url::String; options=Dict())
evaluate(page::Page, expression::String) -> Any
wait_for_selector(page::Page, selector::String; timeout::Int=30000) -> ElementHandle
query_selector(page::Page, selector::String) -> Union{ElementHandle, Nothing}
query_selector_all(page::Page, selector::String) -> Vector{ElementHandle}
click(page::Page, selector::String; options=Dict())
type_text(page::Page, selector::String, text::String; options=Dict())
screenshot(page::Page; options=Dict()) -> String
content(page::Page) -> String
close_page(page::Page)
```

### ElementHandle Functions

```julia
click(element::ElementHandle; options=Dict())
type_text(element::ElementHandle, text::String; options=Dict())
check(element::ElementHandle; options=Dict())
uncheck(element::ElementHandle; options=Dict())
select_option(element::ElementHandle, value::String; options=Dict())
is_visible(element::ElementHandle) -> Bool
get_text(element::ElementHandle) -> String
get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}
evaluate_handle(element::ElementHandle, expression::String) -> Any
```

## Examples

### Launch Browser and Open Page

```julia
using YourPackageName

# Launch a new browser instance
browser = launch_browser(headless=false)

# Create a new browser context
context = new_context(browser)

# Open a new page in the context
page = new_page(context)

# Navigate to a URL
goto(page, "https://www.example.com")

# Close the page
close_page(page)

# Close the browser context
close_context(context)

# Close the browser
close_browser(browser)
```

### Interact with Page Elements

```julia
# Navigate to the page
goto(page, "https://www.example.com/login")

# Type username
type_text(page, "#username", "my_username")

# Type password
type_text(page, "#password", "my_password")

# Click login button
click(page, "#login-button")

# Wait for navigation
wait_for_selector(page, ".dashboard")

# Take a screenshot of the dashboard
screenshot_data = screenshot(page, path="dashboard.png")
```

### Working with Element Handles

```julia
# Query for multiple elements
elements = query_selector_all(page, ".item")

# Iterate over elements
for element in elements
    text = get_text(element)
    println("Item text: $text")
end

# Click the first item
first_item = elements[1]
click(first_item)
```

## Design Considerations

- **Simplicity**: The API is designed to be straightforward and easy to use.
- **Simple Timeout Handling**: Consistent timeout options across functions for user convenience.
- **Type Definitions**: Dedicated types for `Page` and `ElementHandle` to encapsulate page and element operations.
- **Playwright Compatibility**: Function names and behaviors mimic Playwright for ease of migration.
- **Asynchronous Operations**: All functions are synchronous for simplicity. Future versions may introduce async support.

## Error Handling

- Functions return meaningful error messages on failure.
- **Timeouts**: Operations respect specified timeouts and raise errors if exceeded.
- Exceptions are raised for critical failures.