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
  - `types.jl`: Core type definitions (Browser, Page)
  - `core.jl`: CDP method execution and HTTP utilities
- `test/`: Test suite
- `examples/`: Example scripts
- `docs/`: Documentation
  - `src/`: Documentation source files
  - `src/assets/`: Documentation assets and guides
    - `HTTP_CAPABILITIES.md`: Supported features and limitations
    - `HTTP_LIMITATIONS.md`: Known limitations
    - `TROUBLESHOOTING.md`: Common issues and solutions
    - `MIGRATION.md`: Migration guides

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

1. Create a new branch following our naming convention:
```bash
git checkout -b devin/$(date +%s)-your-feature-name
```

2. Implement your changes
3. Add tests
4. Update documentation
5. Submit a pull request

## Common Development Tasks

### Adding New CDP Methods
1. Test the method using Chrome DevTools Protocol documentation
2. Implement the method using `execute_cdp_method`
3. Add error handling and result parsing
4. Add unit tests
5. Update documentation and examples

Example implementation:
```julia
# Example of implementing a new CDP method
browser = Browser("http://localhost:9222")
try
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))

    result = execute_cdp_method(browser, page, "YourDomain.yourMethod", Dict(
        "param1" => "value1",
        "param2" => "value2"
    ))

    if haskey(result, "result")
        # Handle success
    else
        # Handle error
    end
finally
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

### Testing Tips
- Test CDP method responses
- Test error conditions
- Verify edge cases
- Ensure proper HTTP response handling

Example test pattern:
```julia
@testset "CDP Method Tests" begin
    browser = Browser("http://localhost:9222")
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))

    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    @test haskey(result, "result")
    @test haskey(result["result"], "value")

    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
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
