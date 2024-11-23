using ChromeDevToolsLite
using Base64
using Logging

# Set logging level
global_logger(ConsoleLogger(stderr, Logging.Info))

@info "Starting minimal core demo..."

try
    # Connect to Chrome
    @info "Connecting to Chrome..."
    client = connect_browser()

    # Create test content
    @info "Creating test content..."
    send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => """
            document.body.innerHTML = `
                <div id="container" style="padding: 20px; font-family: Arial;">
                    <h1 id="title">ChromeDevToolsLite Demo</h1>
                    <input type="text" id="test-input" placeholder="Type here...">
                    <button id="test-button">Click me</button>
                    <div id="output">Initial text</div>
                </div>
            `;
        """
    ))

    # Test element selection and text content
    @info "Testing element content..."
    title_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "document.querySelector('#title').textContent",
        "returnByValue" => true
    ))
    title = get(get(get(title_result, "result", Dict()), "result", Dict()), "value", "unknown")
    @info "Title text" text=title

    # Test input interaction
    @info "Testing input interaction..."
    send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => """
            const input = document.querySelector('#test-input');
            input.value = 'Hello from Julia!';
        """
    ))

    # Test button click
    @info "Testing button click..."
    send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "document.querySelector('#test-button').click()"
    ))

    # Get page content
    @info "Getting page content..."
    content_result = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}(
        "expression" => "document.documentElement.outerHTML",
        "returnByValue" => true
    ))
    content = get(get(get(content_result, "result", Dict()), "result", Dict()), "value", "unknown")
    @info "Page content retrieved" content_length=length(content)

    # Take screenshot
    @info "Taking screenshot..."
    screenshot_result = send_cdp_message(client, "Page.captureScreenshot", Dict{String,Any}())
    screenshot_data = get(get(screenshot_result, "result", Dict()), "data", nothing)
    if !isnothing(screenshot_data)
        Base.open("minimal_demo.png", "w") do io
            write(io, base64decode(screenshot_data))
        end
        @info "Screenshot saved as minimal_demo.png"
    end

    @info "Demo completed successfully"
    close(client)
catch e
    @error "Demo failed" exception=e
    rethrow()
end
