# Utilities

## Resource Management

### Best Practices
```julia
# Always use try-finally for proper cleanup
client = connect_browser()

try
    # Your page operations here
    goto(client, "https://example.com")
    element = ElementHandle(client, ".content")
finally
    # Clean up
    close(client)
end
```

### Memory Management Tips
- Always close the client connection when done
- Use shorter timeouts for faster failure detection
- Enable verbose logging during development for better debugging
