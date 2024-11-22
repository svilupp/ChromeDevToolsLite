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
  - `types/`: Core type definitions (Browser, Page)
  - `http/`: HTTP endpoint handlers
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

### Adding a New HTTP Endpoint
1. Add endpoint definition in appropriate type file
2. Implement error handling
3. Add unit tests
4. Add example usage
5. Update documentation

Example from our codebase:
```julia
# Example of implementing a new endpoint
browser = connect_browser()
pages = get_pages(browser)
new_page = new_page(browser)
close_page(browser, new_page)
```

### Testing Tips
- Test HTTP endpoint responses
- Test error conditions
- Verify edge cases

Example test pattern:
```julia
try
    browser = connect_browser("http://localhost:9222")
    page = new_page(browser)
catch e
    if e isa HTTP.RequestError
        println("Failed to connect to Chrome")
    else
        println("Unexpected error: ", e)
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
