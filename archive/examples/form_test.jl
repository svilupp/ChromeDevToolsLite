using ChromeDevToolsLite

# Function to ensure Chrome is cleaned up
function cleanup_chrome()
    try
        println("Killing any existing Chrome processes...")
        run(`pkill -f chromium`)
        run(`pkill -f chrome`)
        sleep(2)  # Give Chrome more time to shut down
    catch e
        println("Note: No Chrome processes found to clean up")
    end
end

# Clean up any existing Chrome instances
cleanup_chrome()

println("Starting Chrome in debugging mode...")
# Use explicit host binding and add more Chrome debugging flags
chrome_cmd = `chromium --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --headless --no-sandbox --disable-gpu --disable-software-rasterizer --enable-logging --v=1`
println("Running command: ", chrome_cmd)
run(chrome_cmd, wait=false)
sleep(5)  # Give Chrome more time to start and initialize debugging port

# Verify Chrome debugging endpoint is accessible
try
    println("Verifying debugging endpoint...")
    run(`curl -s http://127.0.0.1:9222/json/version`)
catch e
    println("Warning: Could not verify debugging endpoint: ", e)
end

try
    println("Connecting to browser...")
    browser = connect_browser("http://localhost:9222")

    println("\nCreating new page...")
    page = create_page(browser)

    # Create a simple HTML form
    html_content = """
    <html>
    <body>
        <form>
            <input type="text" id="name" placeholder="Enter your name">
            <button type="submit" id="submit">Submit</button>
        </form>
        <div id="result"></div>
    </body>
    <script>
        document.querySelector('form').onsubmit = (e) => {
            e.preventDefault();
            const name = document.getElementById('name').value;
            document.getElementById('result').textContent = 'Hello, ' + name + '!';
        };
    </script>
    </html>
    """

    # Navigate to blank page and set content
    goto(page, "about:blank")
    set_content(page, html_content)
    sleep(0.5)  # Small delay to ensure DOM is ready

    println("\nInteracting with form...")
    # Find input element and type text
    input = query_selector(page, "#name")
    type_text(input, "Julia User")

    # Find and click submit button
    submit = query_selector(page, "#submit")
    click(submit)
    sleep(1)

    # Get result text
    result = query_selector(page, "#result")
    println("Result: ", get_text(result))

catch e
    println("Error occurred: ", e)
    println(stacktrace(catch_backtrace()))
finally
    println("\nCleaning up...")
    cleanup_chrome()
end
