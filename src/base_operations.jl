"""
    Base.close(browser::AbstractBrowser)

Closes the browser instance and cleans up associated resources.
"""
function Base.close(browser::AbstractBrowser)
    # Implementation in browser.jl
end

"""
    Base.show(io::IO, browser::AbstractBrowser)

Displays information about the browser instance.
"""
function Base.show(io::IO, browser::AbstractBrowser)
    print(io, "Browser()")
end

"""
    Base.close(context::AbstractBrowserContext)

Closes the browser context and all its associated pages.
"""
function Base.close(context::AbstractBrowserContext)
    # Implementation in browser_context.jl
end

"""
    Base.show(io::IO, context::AbstractBrowserContext)

Displays information about the browser context.
"""
function Base.show(io::IO, context::AbstractBrowserContext)
    print(io, "BrowserContext()")
end

"""
    Base.close(page::AbstractPage)

Closes the page and cleans up associated resources.
"""
function Base.close(page::AbstractPage)
    # Implementation in page.jl
end

"""
    Base.show(io::IO, page::AbstractPage)

Displays information about the page.
"""
function Base.show(io::IO, page::AbstractPage)
    print(io, "Page(url=$(page.url))")
end

"""
    Base.close(element::AbstractElementHandle)

Cleans up resources associated with the element handle.
"""
function Base.close(element::AbstractElementHandle)
    # Implementation in element_handle.jl
end

"""
    Base.show(io::IO, element::AbstractElementHandle)

Displays information about the element handle.
"""
function Base.show(io::IO, element::AbstractElementHandle)
    print(io, "ElementHandle()")
end
