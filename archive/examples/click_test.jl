using ChromeDevToolsLite

# Kill any existing Chrome processes (ignore errors)
try
    run(`pkill chrome`)
catch
end
sleep(1)

println("Starting Chrome...")
# Start Chrome with absolute minimal flags
run(`google-chrome --remote-debugging-port=9222 --headless=new`)
sleep(2)

println("Attempting to connect to browser at http://localhost:9222...")
try
    global browser = connect_browser("http://localhost:9222")
    println("Browser connection successful!")

    global page = get_page(browser)
    println("Page handle acquired!")

    println("\nSetting up test page...")
    set_content(page, """
        <button id="test-button">Click me</button>
    """)

    println("\nLocating button...")
    button = query_selector(page, "#test-button")
    println("Button found!")

    println("Clicking button...")
    click(button)
    println("Click executed!")
catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up Chrome process...")
    try
        run(`pkill chrome`)
    catch
    end
end
