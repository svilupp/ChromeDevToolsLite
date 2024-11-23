# ChromeDevToolsLite Examples

This directory contains examples demonstrating the HTTP-only CDP implementation capabilities.

## Prerequisites
- Chrome/Chromium running with remote debugging enabled:
  ```bash
  chromium --remote-debugging-port=9222
  ```
- Julia 1.10 or higher
- ChromeDevToolsLite package installed

## Examples Overview

### 1. Basic Usage (`01_basic_usage.jl`)
Demonstrates core functionality:
- Browser connection
- Page creation and management
- Basic navigation
- JavaScript evaluation
- Error handling

### 2. JavaScript Evaluation (`02_javascript_evaluation.jl`)
Shows advanced JavaScript operations:
- Complex DOM queries
- Page analysis
- State verification
- Return value handling

### 3. Form Interaction (`03_form_interaction.jl`)
Illustrates form handling:
- Form field detection
- Input manipulation
- Event simulation
- Form submission

### 4. Error Handling (`04_error_handling.jl`)
Covers error handling patterns:
- CDP method errors
- JavaScript exceptions
- Navigation failures
- Recovery strategies

### 5. State Management (`05_state_management.jl`)
Demonstrates state management utilities:
- Page state verification
- Navigation state tracking
- Batch element updates
- Form state validation
- Error recovery patterns

## Running Examples

1. Start Chrome with debugging enabled:
   ```bash
   chromium --remote-debugging-port=9222
   ```

2. Run an example:
   ```bash
   julia examples/01_basic_usage.jl
   ```

## Common Patterns

### State Management
```julia
# Verify page state with timeout
state = verify_page_state(browser, page)
if state !== nothing
    println("Page loaded: ", state["url"])
    println("Page metrics:", state["metrics"])
end

# Batch element updates
updates = Dict(
    "#username" => "user123",
    "#email" => "test@example.com",
    "#password" => "pass456"
)
result = batch_update_elements(browser, page, updates)
for (selector, success) in result
    println("Update $selector: ", success ? "✓" : "✗")
end
```

### Navigation with Verification
```julia
# Navigate to URL
result = execute_cdp_method(browser, page, "Page.navigate", Dict(
    "url" => "https://example.com"
))

# Verify page load with state management
state = verify_page_state(browser, page)
if state !== nothing && state["ready"]
    println("Navigation successful")
    println("Page title: ", state["title"])
    println("Found ", state["metrics"]["links"], " links")
end
```

### DOM Operations
```julia
# Element manipulation
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const el = document.querySelector('.target');
        if (el) {
            el.textContent = 'New Content';
            return true;
        }
        return false;
    """,
    "returnByValue" => true
))
```

### Batch Operations
```julia
# Multiple form updates in single call
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const updates = {
            '#username': 'testuser',
            '#email': 'test@example.com',
            '#remember': true
        };
        const results = {};
        for (const [selector, value] of Object.entries(updates)) {
            const el = document.querySelector(selector);
            if (el) {
                if (typeof value === 'boolean') {
                    el.checked = value;
                } else {
                    el.value = value;
                }
                el.dispatchEvent(new Event('input'));
                results[selector] = true;
            } else {
                results[selector] = false;
            }
        }
        return results;
    """,
    "returnByValue" => true
))
```

### Error Handling
```julia
try
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("CDP error: ", result["error"])
    else
        println("Title: ", result["result"]["value"])
    end
finally
    page !== nothing && close_page(browser, page)
end
```

## Notes
- All examples use HTTP-only CDP methods
- State management utilities provide reliable operation verification
- Batch operations optimize performance
- WebSocket-dependent features are not available
- See [HTTP_LIMITATIONS.md](../HTTP_LIMITATIONS.md) for constraints
- See [MIGRATION.md](../MIGRATION.md) for transition guide
