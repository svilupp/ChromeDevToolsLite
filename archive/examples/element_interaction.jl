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

println("\nBasic element interactions via JavaScript:")

# 1. Create and modify an element
println("\n1. Creating and styling an element")
result = send_cdp_message(client, Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """
        const div = document.createElement('div');
        div.id = 'test-element';
        div.textContent = 'Test Content';
        div.style.backgroundColor = 'blue';
        div.style.color = 'white';
        div.style.padding = '10px';
        document.body.appendChild(div);
        div.outerHTML
        """,
        "returnByValue" => true
    )
))
println("Created element: ", result.result.result.value)

# 2. Query and modify element
println("\n2. Modifying element")
result = send_cdp_message(client, Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """
        const el = document.getElementById('test-element');
        el.textContent = 'Modified Content';
        el.textContent
        """,
        "returnByValue" => true
    )
))
println("Modified content: ", result.result.result.value)

# 3. Element properties
println("\n3. Getting element properties")
result = send_cdp_message(client, Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => """
        const el = document.getElementById('test-element');
        ({
            id: el.id,
            content: el.textContent,
            styles: el.style.cssText
        })
        """,
        "returnByValue" => true
    )
))
println("Properties: ", JSON3.pretty(result.result.result.value))

# Clean up
close(client)
