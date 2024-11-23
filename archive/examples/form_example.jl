using ChromeDevToolsLite
using HTTP

# Kill any existing Chrome processes
try
    run(`pkill -f chromium`)
    sleep(1)
catch
end

println("Starting Chrome in debugging mode...")
run(`chromium --remote-debugging-port=9222 --headless --no-sandbox`, wait=false)

# Wait for Chrome to be ready
println("Waiting for Chrome to start...")
max_retries = 10
for i in 1:max_retries
    try
        response = HTTP.get("http://localhost:9222/json/version")
        if response.status == 200
            println("Chrome is ready!")
            break
        end
    catch
        if i == max_retries
            error("Failed to connect to Chrome after $max_retries attempts")
        end
        println("Waiting for Chrome (attempt $i/$max_retries)...")
        sleep(2)
    end
end

println("Connecting to Chrome...")
browser = connect_browser("http://localhost:9222")

println("Creating new page...")
target = send_cdp_message(browser, "Target.createTarget", Dict("url" => "about:blank"))
@debug "Target response:" target
target_id = get(target, "targetId", "")

println("Attaching to target...")
session = send_cdp_message(browser, "Target.attachToTarget", Dict(
    "targetId" => target_id,
    "flatten" => true
))
@debug "Session response:" session

page = Page(browser, target_id, target_id)

println("Navigating to form...")
goto(page, "https://httpbin.org/forms/post")

# Find and interact with form elements
custname = query_selector(page, "input[name='custname']")
if custname !== nothing
    println("Typing customer name...")
    type_text(custname, "John Doe")
end

# Find and click the submit button
submit_btn = query_selector(page, "input[type='submit']")
if submit_btn !== nothing
    println("Clicking submit button...")
    click(submit_btn)
end

println("Test complete!")

# Cleanup
println("\nCleaning up...")
try
    run(`pkill -f chromium`)
catch
end
