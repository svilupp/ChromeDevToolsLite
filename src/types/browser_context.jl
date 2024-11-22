"""
    BrowserContext

Represents an isolated browser context that contains a set of pages.
"""
mutable struct BrowserContext <: AbstractBrowserContext
    browser::AbstractBrowser
    pages::Vector{AbstractPage}
    options::Dict{AbstractString,<:Any}
    context_id::AbstractString
    verbose::Bool

    # Default constructor
    function BrowserContext(browser::Browser; verbose::Bool=false)
        # Create browser context via CDP
        request = create_cdp_message("Target.createBrowserContext", Dict{String,<:Any}())
        verbose && @info "Creating new browser context..."
        response_channel = send_message(browser.session, request)
        response = take!(response_channel)

        if !isnothing(response.error)
            error("Failed to create browser context: $(response.error["message"])")
        end

        context_id = response.result["browserContextId"]
        verbose && @info "Browser context created with ID: $context_id"
        new(browser, AbstractPage[], Dict{String,<:Any}(), context_id, verbose)
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
    context.verbose && @info "Creating new page in context" context_id=context.context_id

    # Create new target
    params = Dict{String,<:Any}("browserContextId" => context.context_id)
    request = create_cdp_message("Target.createTarget", merge(params, Dict{String,<:Any}("url" => "about:blank")))
    response_channel = send_message(context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to create page: $(response.error["message"])")
    end

    target_id = response.result["targetId"]
    context.verbose && @info "Target created" target_id=target_id

    # Attach to target
    attach_params = Dict{String,<:Any}("targetId" => target_id)
    attach_request = create_cdp_message("Target.attachToTarget", merge(attach_params, Dict{String,<:Any}("flatten" => true)))
    response_channel = send_message(context.browser.session, attach_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to attach to target: $(response.error["message"])")
    end
    context.verbose && @info "Attached to target" target_id=target_id

    page = Page(context, response.result["sessionId"], target_id, Dict{String,<:Any}(), verbose=context.verbose)

    # Enable required domains
    enable_msg = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => "Runtime.enable",
        "params" => Dict{String,<:Any}(),
        "id" => get_next_message_id()
    )
    response_channel = send_message(context.browser.session, enable_msg)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to enable Runtime domain: $(response.error["message"])")
    end
    context.verbose && @info "Runtime domain enabled for page" target_id=target_id

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
    context.verbose && @info "Closing browser context and all pages" context_id=context.context_id
    foreach(close, context.pages)
end

export pages, new_page, create_page
