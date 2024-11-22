using ChromeDevToolsLite
using Test

@info "Starting WebSocket connection test..."

# Launch browser and test WebSocket connection
browser = nothing
try
    browser = launch_browser(headless=true)
    @test browser isa Browser
    @info "✓ Browser launched successfully"

    # Test WebSocket connection by sending a simple CDP command
    request = create_cdp_message("Browser.getVersion", Dict{String,Any}())
    response_channel = send_message(browser.session, request)
    response = take!(response_channel)

    @test !isnothing(response.result)
    @test haskey(response.result, "product")
    @info "✓ WebSocket communication successful"
    @info "Browser version: $(response.result["product"])"

catch e
    @error "Test failed" exception=e
    rethrow(e)
finally
    if !isnothing(browser)
        close(browser)
        @info "✓ Browser closed"
    end
end
