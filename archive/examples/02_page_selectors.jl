using ChromeDevToolsLite
using Test
using HTTP

# Create a test page with various elements to test selectors
const TEST_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Selector Test Page</title>
</head>
<body>
    <div id="visible">Visible Element</div>
    <div id="hidden" style="display: none;">Hidden Element</div>
    <div class="counter">Item 1</div>
    <div class="counter">Item 2</div>
    <div class="counter">Item 3</div>
    <input type="text" id="input-test" value="test value"/>
</body>
</html>
"""

# Start HTTP server
const TEST_PORT = 8124
server = HTTP.serve!("127.0.0.1", TEST_PORT) do request
    return HTTP.Response(200, TEST_HTML)
end

@info "Starting selector tests..."

try
    # Launch browser
    browser = launch_browser(headless=true)
    context = create_browser_context(browser)
    page = create_page(context)

    # Navigate to test page
    test_url = "http://localhost:$TEST_PORT"
    goto(page, test_url)

    # Wait a moment for the page to load
    sleep(1)

    # Test visibility
    @test evaluate(page, """
        const element = document.querySelector('#visible');
        if (!element) return false;
        const style = window.getComputedStyle(element);
        return style && style.display !== 'none' && style.visibility !== 'hidden';
    """) == true

    @test evaluate(page, """
        const element = document.querySelector('#hidden');
        if (!element) return false;
        const style = window.getComputedStyle(element);
        return style && style.display !== 'none' && style.visibility !== 'hidden';
    """) == false

    # Test element count
    @test evaluate(page, "document.querySelectorAll('.counter').length") == 3

    # Test get text
    @test evaluate(page, "document.querySelector('#visible').textContent") == "Visible Element"

    # Test get value
    @test evaluate(page, "document.querySelector('#input-test').value") == "test value"

    @info "✓ Page selector tests successful"

catch e
    @error "Test failed" exception=e
    rethrow(e)
finally
    # Cleanup
    if @isdefined page
        close(page)
    end
    if @isdefined context
        close(context)
    end
    if @isdefined browser
        close(browser)
    end
    close(server)
    @info "✓ Cleanup completed"
end
