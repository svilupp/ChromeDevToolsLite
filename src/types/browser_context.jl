"""
    BrowserContext

Represents an isolated browser context that contains a set of pages.
"""
mutable struct BrowserContext <: AbstractBrowserContext
    browser::AbstractBrowser
    pages::Vector{AbstractPage}
    options::Dict{String, Any}
    context_id::String

    # Default constructor
    function BrowserContext(browser::Browser)
        # Create browser context via CDP
        request = create_cdp_message("Target.createBrowserContext", Dict{String,Any}())
        response_channel = send_message(browser.session, request)
        response = take!(response_channel)

        if !isnothing(response.error)
            error("Failed to create browser context: $(response.error["message"])")
        end

        context_id = response.result["browserContextId"]
        new(browser, AbstractPage[], Dict{String, Any}(), context_id)
    end
end

"""
    Base.show(io::IO, context::BrowserContext)

Custom display for BrowserContext instances.
"""
function Base.show(io::IO, context::BrowserContext)
    page_count = length(context.pages)
    print(io, "BrowserContext(pages=$page_count, id=$(context.context_id))")
end

"""
    pages(context::BrowserContext) -> Vector{Page}

Lists all pages in the context.
"""
function pages(context::BrowserContext)
    return context.pages
end

"""
    create_page(context::BrowserContext) -> Page

Creates a new page in the context.
"""
function create_page(context::BrowserContext)
    # Create new target
    params = Dict{String,Any}("browserContextId" => context.context_id)
    request = create_cdp_message("Target.createTarget", merge(params, Dict("url" => "about:blank")))
    response_channel = send_message(context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to create page: $(response.error["message"])")
    end

    target_id = response.result["targetId"]

    # Attach to target
    attach_params = Dict{String,Any}("targetId" => target_id)
    attach_request = create_cdp_message("Target.attachToTarget", merge(attach_params, Dict("flatten" => true)))
    response_channel = send_message(context.browser.session, attach_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to attach to target: $(response.error["message"])")
    end

    page = Page(context, response.result["sessionId"], target_id, Dict{String,Any}())

    # Enable required domains
    enable_msg = Dict{String,Any}(
        "sessionId" => page.session_id,
        "method" => "Runtime.enable",
        "params" => Dict{String,Any}(),
        "id" => get_next_message_id()
    )
    response_channel = send_message(context.browser.session, enable_msg)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to enable Runtime domain: $(response.error["message"])")
    end

    push!(context.pages, page)
    return page
end

# Alias for backward compatibility
const new_page = create_page

"""
    Base.close(context::BrowserContext)

Ensures proper cleanup of context resources.
"""
function Base.close(context::BrowserContext)
    # Close all pages in the context
    foreach(close, context.pages)
end

export pages, new_page, create_page
