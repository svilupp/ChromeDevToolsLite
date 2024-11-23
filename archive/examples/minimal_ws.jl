using ChromeDevToolsLite
using JSON3
using HTTP

function test_connection()
    println("Getting WebSocket URL...")
    ws_url = get_ws_url()
    println("WebSocket URL: ", ws_url)

    println("\nConnecting to Chrome...")
    HTTP.WebSockets.open(ws_url) do ws
        client = ChromeClient(ws, Ref(1))
        println("Connected successfully!")

        println("\nTesting CDP command...")
        result = send_cdp_message(client, Dict(
            "method" => "Page.navigate",
            "params" => Dict("url" => "about:blank")
        ))
        println("Response: ", JSON3.write(result))
    end
    println("\nTest completed!")
end

try
    test_connection()
catch e
    println("Error: ", e)
end
