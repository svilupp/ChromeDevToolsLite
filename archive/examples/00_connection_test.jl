using ChromeDevToolsLite
using Test

@info "Starting basic connection test..."

try
    # Launch browser
    browser = launch_browser(headless=true)
    @test browser isa Browser
    @info "✓ Browser launched successfully"

    # Test basic CDP command
    request = create_cdp_message("Browser.getVersion", Dict{String,Any}())
    response_channel = send_message(browser.session, request)

    # Create a task to fetch the response
    response_task = @async take!(response_channel)

    # Wait for response with timeout
    response = nothing
    timedout = false

    for _ in 1:50
        if istaskdone(response_task)
            response = fetch(response_task)
            break
        end
        sleep(0.1)
    end

    if isnothing(response)
        timedout = true
        @error "Timeout waiting for CDP response"
    end

    @test !timedout
    @test !isnothing(response)
    @test !isnothing(response.result)
    @test haskey(response.result, "product")
    @info "✓ CDP command successful"
    @info "Browser version: $(response.result["product"])"

catch e
    @error "Test failed" exception=e
    rethrow(e)
finally
    # Clean up
    if @isdefined browser
        close(browser)
        @info "✓ Browser closed"
    end
end
