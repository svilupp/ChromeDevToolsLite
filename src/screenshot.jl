"""
    take_screenshot(page::Page; format::String="png", quality::Union{Nothing,Int}=nothing) -> Vector{UInt8}

Take a screenshot of the current page. Returns the raw bytes of the image.
format can be "png" or "jpeg". Quality (0-100) only applies to jpeg format.
"""
function take_screenshot(page::Page; format::String="png", quality::Union{Nothing,Int}=nothing)
    # Ensure Page domain is enabled
    send_cdp_message(page.browser, "Page.enable", Dict("sessionId" => page.session_id))

    # Validate format
    if format ∉ ["png", "jpeg"]
        throw(ArgumentError("Screenshot format must be 'png' or 'jpeg'"))
    end

    # Validate quality for JPEG
    if format == "jpeg" && quality !== nothing
        if !(0 ≤ quality ≤ 100)
            throw(ArgumentError("JPEG quality must be between 0 and 100"))
        end
    end

    # Prepare screenshot parameters
    params = Dict(
        "format" => format,
        "sessionId" => page.session_id,
        "fromSurface" => true  # More reliable rendering
    )

    if format == "jpeg" && quality !== nothing
        params["quality"] = quality
    end

    # Take screenshot with timeout
    result = send_cdp_message(page.browser, "Page.captureScreenshot", params)

    # Decode base64 data
    if haskey(result, "data")
        return base64decode(result["data"])
    end

    throw(ErrorException("Failed to capture screenshot: no data received"))
end

export take_screenshot
