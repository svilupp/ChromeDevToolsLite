using HTTP
using JSON3

# Try to get the list of available debugging targets
try
    response = HTTP.get("http://localhost:9222/json")
    println("Available targets:")
    println(String(response.body))
catch e
    println("Error connecting to Chrome debugging port:")
    println(e)
end
