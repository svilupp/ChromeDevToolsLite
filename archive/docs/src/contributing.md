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
4. Include examples in docstrings
5. Write unit tests for new functionality

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
2. Implement error handling
3. Add unit tests
4. Add example usage
5. Update documentation

Example from our codebase:
```julia
# From examples/14_evaluate_handle_test.jl
# Implementation of evaluate_handle
element = query_selector(page, "#myButton")
result = evaluate_handle(element, "el => el.textContent")
```

### Testing Tips
- Use `MockWebSocket` for CDP tests
- Test error conditions and timeouts
- Verify edge cases

Example test pattern:
```julia
# From examples/05_error_handling.jl
try
    element = wait_for_selector(page, "#non-existent", timeout=5000)
catch e
    if e isa TimeoutError
        println("Element not found within timeout period")
    elseif e isa ElementNotFoundError
        println("Element does not exist on the page")
    end
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
