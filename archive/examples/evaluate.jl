using ChromeDevToolsLite
using HTTP
using JSON3

# Example assumes Chrome is already running with remote debugging enabled:
# chromium --remote-debugging-port=9222 --headless

# Get available debugging targets
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
target = first(filter(t -> t.type == "page", targets))

println("Connecting to target: ", target.title)
client = connect_chrome(target.webSocketDebuggerUrl)

println("\nDemonstrating JavaScript evaluation examples:")

# Example 1: Basic JavaScript evaluation
println("\n1. Basic JavaScript evaluation")
msg1 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "2 + 2",
        "returnByValue" => true
    )
)
response = send_cdp_message(client, msg1)
println("Result: ", response.result.result.value)

# Example 2: DOM query
println("\n2. DOM query")
msg2 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """
        document.querySelector('html').getAttribute('lang') || 'no lang attribute'
        """,
        "returnByValue" => true
    )
)
response = send_cdp_message(client, msg2)
println("HTML lang: ", response.result.result.value)

# Example 3: Page metrics
println("\n3. Page metrics")
msg3 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """({
            url: window.location.href,
            userAgent: navigator.userAgent,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight,
                devicePixelRatio: window.devicePixelRatio
            }
        })""",
        "returnByValue" => true
    )
)
response = send_cdp_message(client, msg3)
println("Metrics: ", response.result.result.value)

# Example 4: DOM modification
println("\n4. DOM modification")
msg4 = Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """
        const div = document.createElement('div');
        div.textContent = 'Added by CDP';
        document.body.appendChild(div);
        'Element added'
        """,
        "returnByValue" => true
    )
)
response = send_cdp_message(client, msg4)
println("Status: ", response.result.result.value)

# Clean up
close(client)
