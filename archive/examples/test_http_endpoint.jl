using HTTP
using JSON
using Sockets

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(1)

# Start Chrome with minimal flags
println("Launching Chrome...")
chrome_proc = run(`google-chrome --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)
sleep(2)

println("\nVerifying Chrome process and port...")
# Check if port 9222 is listening
try
    server = connect("localhost", 9222)
    close(server)
    println("Port 9222 is accessible")
catch e
    println("Error connecting to port 9222: ", e)
    rethrow(e)
end

println("\nTesting HTTP endpoint...")
try
    # Configure HTTP request with explicit timeouts
    headers = ["Accept" => "*/*", "User-Agent" => "Julia/1.10.6"]
    opts = Dict(
        :readtimeout => 5,
        :connecttimeout => 5,
        :retry => false,
        :retries => 1
    )

    # First try to get the list of pages
    println("GET /json")
    response = HTTP.request("GET", "http://localhost:9222/json", headers; opts...)
    println("Response status: ", response.status)
    println("Response body: ", String(response.body))

    # Then try to get the version info
    println("\nGET /json/version")
    version_response = HTTP.request("GET", "http://localhost:9222/json/version", headers; opts...)
    println("Response status: ", version_response.status)
    println("Response body: ", String(version_response.body))
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
