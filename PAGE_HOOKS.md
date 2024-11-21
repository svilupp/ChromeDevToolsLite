# Global Page Hooks in Browser Automation

## Overview

Global page hooks allow developers to define JavaScript scripts that are automatically injected into every page within a browser context. This ensures consistent behavior across all pages, especially after navigation events like `goto` or `click` that may cause the page to reload or navigate to a new URL.

An example use case is adding a visual cursor indicator that remains present and functional across all pages and navigation events.

## Global Page Hooks API

### Description

The Global Page Hooks API provides functions to register, unregister, and list global hooks. These hooks are scripts that are injected into pages at the appropriate times to maintain desired functionalities.

### API Functions

```julia
"""
    register_global_hook(context::BrowserContext, name::String, script::String)

Registers a global hook script under a given `name` to be injected into every page within the `context`. 
The script will be re-injected after any navigation events.
"""
function register_global_hook(context::BrowserContext, name::String, script::String)
    # Implementation code
end

"""
    unregister_global_hook(context::BrowserContext, name::String)

Unregisters a previously registered global hook script identified by `name` from the `context`.
"""
function unregister_global_hook(context::BrowserContext, name::String)
    # Implementation code
end

"""
    list_global_hooks(context::BrowserContext) -> Vector{String}

Returns a list of names of all registered global hooks in the `context`.
"""
function list_global_hooks(context::BrowserContext) -> Vector{String}
    # Implementation code
end
```

## Implementation Details

### How Scripts Are Injected and Re-injected

#### Injection Upon Page Creation

When a new page is created within a browser context, the registered global hooks are injected into the page before any other script runs. This is achieved using the page's `add_init_script` method, which adds the script to the page's initialization sequence.

```julia
function initialize_page(page::Page)
    # Inject global hooks into the page
    for (name, script) in page.context.global_hooks
        add_init_script(page, script)
    end
end
```

#### Re-injection After Navigation Events

After navigation events such as `goto` or actions like `click` that result in page reloads or navigations, the page's content is replaced, and any injected scripts may be lost. To ensure that the global hooks remain active, the scripts are re-injected after each navigation.

This is achieved by listening to the page's `DOMContentLoaded` or `load` events and re-injecting the scripts.

```julia
function attach_navigation_listeners(page::Page)
    page.on("framenavigated", () -> begin
        # Re-inject global hooks into the page
        for (name, script) in page.context.global_hooks
            page.evaluate(script)
        end
    end)
end
```

#### Ensuring Script Presence

To ensure that the scripts are present and do not cause duplication:

- **Unique Identifiers**: Each script checks for a unique element or global variable (e.g., an element with a specific ID) before executing its main logic. This prevents duplicate elements or event listeners from being added.
- **Event Listeners**: Event listeners are added in such a way that they do not accumulate duplicates on each injection.

### Modifications to Existing API

#### `BrowserContext` Enhancements

```julia
mutable struct BrowserContext
    # Existing fields
    pages::Vector{Page}
    # New field to store global hooks
    global_hooks::Dict{String, String}
end

function register_global_hook(context::BrowserContext, name::String, script::String)
    context.global_hooks[name] = script
    # Ensure the script is injected into all existing pages
    for page in context.pages
        add_init_script(page, script)
        page.evaluate(script)
    end
end

function unregister_global_hook(context::BrowserContext, name::String)
    delete!(context.global_hooks, name)
    # Optionally, remove the effects of the script from existing pages
end

function list_global_hooks(context::BrowserContext) -> Vector{String}
    return collect(keys(context.global_hooks))
end
```

#### Page Loading and Navigation Behavior

```julia
function new_page(context::BrowserContext) -> Page
    page = # Create a new page within the context
    # Initialize the page with global hooks
    initialize_page(page)
    # Attach navigation listeners to re-inject hooks after navigations
    attach_navigation_listeners(page)
    # Add the page to the context's pages list
    push!(context.pages, page)
    return page
end

# Whenever a navigation method is called, ensure hooks are re-injected
function goto(page::Page, url::String; options...)
    # Perform the navigation
    # After navigation completes, hooks will be re-injected via listeners
end

function click(page::Page, selector::String; options...)
    # Perform the click action
    # If the click causes a navigation, hooks will be re-injected via listeners
end
```

## Example Usage

```julia
using YourPackageName

# Launch a new browser instance
browser = launch_browser(headless=false)

# Create a new browser context
context = new_context(browser)

# Define the cursor visualization script
cursor_script = raw"""
(function() {
    if (!document.getElementById('custom-cursor-indicator')) {
        const cursor = document.createElement('div');
        cursor.id = 'custom-cursor-indicator';
        cursor.style.cssText = `
            width: 20px;
            height: 20px;
            border: 2px solid red;
            border-radius: 50%;
            position: fixed;
            pointer-events: none;
            z-index: 99999;
            transform: translate(-50%, -50%);
            opacity: 0;
            transition: opacity 0.2s;
        `;
        document.body.appendChild(cursor);

        let timeoutId;
        document.addEventListener('mousemove', (e) => {
            cursor.style.left = e.pageX + 'px';
            cursor.style.top = e.pageY + 'px';
            cursor.style.opacity = '1';

            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => {
                cursor.style.opacity = '0';
            }, 2000); // Adjust timeout as needed
        });
    }
})();
"""

# Register the global cursor hook
register_global_hook(context, "cursor_visibility", cursor_script)

# Open a new page in the context
page = new_page(context)

# The cursor visualization script is automatically injected and re-injected as needed
goto(page, "https://www.example.com")

# Perform actions that may cause navigations
click(page, "#some-link-that-navigates")

# The cursor script remains active after navigation

# Close resources
close_page(page)
close_context(context)
close_browser(browser)
```

## Benefits

- **Consistency Across Navigations**: Ensures that scripts remain active regardless of page reloads or navigations.
- **Clean API**: Provides a simple interface to manage global scripts without repetitive code in individual pages.
- **Performance**: Scripts are injected efficiently without unnecessary duplication or overhead.
- **Flexibility**: Developers can modify or remove hooks at runtime, affecting all pages within the context.