# Page Operations

This module provides functions for page navigation, content manipulation, and page management.

## Navigation and Content

```julia
goto(client::WSClient, url::String; options=Dict())
```
Navigates to the specified URL. Options can include `timeout` and `waitUntil` parameters.

```julia
content(client::WSClient)
```
Returns the current page's HTML content.

```julia
evaluate(client::WSClient, expression::String)
```
Evaluates JavaScript code in the context of the current page.

```julia
screenshot(client::WSClient; options=Dict())
```
Takes a screenshot of the current page. Options include `path`, `fullPage`, and `quality`.

## Page Management

```julia
new_page(client::WSClient)
```
Creates a new page in the current browser context.

```julia
get_all_pages(client::WSClient)
```
Returns all open pages in the current browser context.

```julia
get_page_info(client::WSClient)
```
Retrieves information about the current page.

## Viewport Control

```julia
get_viewport(client::WSClient)
```
Gets the current viewport dimensions and settings.

```julia
set_viewport!(client::WSClient, viewport::Dict)
```
Sets the viewport dimensions and settings.

## Page State

```julia
wait_for_ready_state(client::WSClient; state::String="complete")
```
Waits for the page to reach a specific ready state ("loading", "interactive", or "complete").

```julia
is_active(client::WSClient)
```
Checks if the current page is active.

## Examples

```julia
# Basic navigation and screenshot
goto(client, "https://example.com")
wait_for_ready_state(client)
screenshot(client, Dict("path" => "example.png"))

# Create and manage multiple pages
new_page = new_page(client)
pages = get_all_pages(client)

# Set custom viewport
set_viewport!(client, Dict(
    "width" => 1920,
    "height" => 1080,
    "deviceScaleFactor" => 1.0
))

# Evaluate JavaScript
result = evaluate(client, """
    document.querySelector('h1').textContent
""")
```

See the complete examples in `examples/2_page_operations.jl`.
