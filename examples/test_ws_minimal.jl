using ChromeDevToolsLite

println("Connecting to Chrome...")
client = connect_browser()
println("Connected!")

# Send a simple command
response = send_cdp_message(client, "Browser.getVersion", Dict{String,Any}())
println("Response: ", response)

# Clean up
close(client)
println("\nConnection closed.")
