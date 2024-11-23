# Contributing to ChromeDevToolsLite.jl

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/svilupp/ChromeDevToolsLite.jl
cd ChromeDevToolsLite.jl
```

2. Install dependencies:
```julia
using Pkg
Pkg.develop(path=".")
```

3. Install Chromium (required for testing):
```bash
# Ubuntu/Debian
sudo apt-get install chromium-browser

# macOS
brew install chromium
```

## Project Structure

- `src/`: Source code
  - `types/`: Core type definitions
  - `cdp/`: Chrome DevTools Protocol handling
  - `utils/`: Utility functions
- `test/`: Test suite
- `examples/`: Example scripts
- `docs/`: Documentation

## Running Tests

```julia
using Pkg
Pkg.test("ChromeDevToolsLite")
```

Note: Some tests require a running Chromium instance with remote debugging enabled.

## Code Style Guidelines

1. Follow Julia style guide
2. Use meaningful variable names
3. Add docstrings for all public functions
4. Include examples in docstrings with verbose flag options
5. Write unit tests for new functionality
6. Use verbose flag for debugging operations

## Adding New Features

1. Create a new branch:
```bash
git checkout -b feature/your-feature-name
```

2. Implement your changes
3. Add tests
4. Update documentation
5. Submit a pull request

## Common Development Tasks

### Adding a New CDP Command
1. Add command definition in appropriate type file
2. Implement error handling and verbose logging
3. Add unit tests with verbose mode coverage
4. Add example usage with verbose options
5. Update documentation

Example from our codebase:
```julia
# From examples/14_evaluate_handle_test.jl
# Implementation of evaluate_handle with verbose logging
element = ElementHandle(client, "#myButton", verbose=true)
result = evaluate_handle(element, "el => el.textContent", verbose=true)
```

### Testing Tips
- Use `MockWebSocket` for CDP tests
- Test error conditions and timeouts
- Verify edge cases
- Test with both verbose=true and verbose=false

Example test pattern:
```julia
# Example error handling with verbose logging
try
    element = ElementHandle(client, "#non-existent", verbose=true)
    if !isnothing(element)
        click(element, verbose=true)
    end
catch e
    println("Element interaction failed: ", e)
end
```

## Documentation

Build documentation locally:
```julia
using Documenter
include("docs/make.jl")
```

## Getting Help

- Open an issue for bugs
- Discuss major changes in issues first
- Join Julia Slack for questions
