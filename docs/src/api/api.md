# API Reference

## Core Functions

### Browser Connection
```julia
connect_browser(; verbose=false)
```
Connects to a Chrome browser instance running with remote debugging enabled.

### Page Navigation and Content
```julia
goto(client, url)
```
Navigates to the specified URL.

```julia
content(client)
```
Gets the HTML content of the current page.

```julia
evaluate(client, script)
```
Executes JavaScript code on the current page and returns the result.

```julia
screenshot(client; verbose=false)
```
Takes a screenshot of the current page.

### Resource Management
```julia
close(client)
```
Closes the connection to the browser.

## Best Practices

### Error Handling
```julia
try
    client = connect_browser(verbose=true)
    try
        goto(client, "https://example.com")
        result = evaluate(client, "document.title")
        println("Page title: $result")
    finally
        close(client)
    end
catch e
    @warn "Browser automation failed" exception=e
    rethrow(e)
end
```

### JavaScript Evaluation
```julia
# Simple evaluation
title = evaluate(client, "document.title")

# Complex DOM operations
evaluate(client, """
    const button = document.querySelector('#submit');
    if (button) {
        button.click();
        return true;
    }
    return false;
""")

# Form handling
evaluate(client, """
    const form = document.querySelector('form');
    if (form) {
        form.querySelector('input[name="username"]').value = 'user123';
        form.querySelector('input[name="password"]').value = 'pass123';
        form.submit();
        return true;
    }
    return false;
""")
```

### Screenshots
```julia
# Take a full page screenshot
screenshot(client, verbose=true)
```
