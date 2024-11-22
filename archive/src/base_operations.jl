"""
    close(browser::AbstractBrowser)

Close the browser instance and clean up associated resources.

# Examples
```julia
browser = Browser()
try
    # Use browser
finally
    close(browser)
end
```
"""
function Base.close(browser::AbstractBrowser)
    # Implementation in browser.jl
end

"""
    show(io::IO, browser::AbstractBrowser)

Display information about the browser instance.

# Examples
```julia
browser = Browser()
println(browser)  # outputs: Browser()
```
"""
function Base.show(io::IO, browser::AbstractBrowser)
    print(io, "Browser()")
end

"""
    close(context::AbstractBrowserContext)

Close the browser context and all its associated pages.

# Examples
```julia
browser = Browser()
context = new_context(browser)
try
    # Use context
finally
    close(context)
end
```
"""
function Base.close(context::AbstractBrowserContext)
    # Implementation in browser_context.jl
end

"""
    show(io::IO, context::AbstractBrowserContext)

Display information about the browser context.

# Examples
```julia
context = new_context(browser)
println(context)  # outputs: BrowserContext()
```
"""
function Base.show(io::IO, context::AbstractBrowserContext)
    print(io, "BrowserContext()")
end

"""
    close(page::AbstractPage)

Close the page and clean up associated resources.

# Examples
```julia
page = new_page(context)
try
    # Use page
finally
    close(page)
end
```
"""
function Base.close(page::AbstractPage)
    # Implementation in page.jl
end

"""
    show(io::IO, page::AbstractPage)

Display information about the page.

# Examples
```julia
page = new_page(context)
println(page)  # outputs: Page(url=about:blank)
```
"""
function Base.show(io::IO, page::AbstractPage)
    print(io, "Page(url=$(page.url))")
end

"""
    close(element::AbstractElementHandle)

Clean up resources associated with the element handle.

# Examples
```julia
element = query_selector(page, "#my-element")
try
    # Use element
finally
    close(element)
end
```
"""
function Base.close(element::AbstractElementHandle)
    # Implementation in element_handle.jl
end

"""
    show(io::IO, element::AbstractElementHandle)

Display information about the element handle.

# Examples
```julia
element = query_selector(page, "#my-element")
println(element)  # outputs: ElementHandle()
```
"""
function Base.show(io::IO, element::AbstractElementHandle)
    print(io, "ElementHandle()")
end
