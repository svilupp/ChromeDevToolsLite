"""
    Base.close(browser::AbstractBrowser)

Closes the browser instance and cleans up associated resources.
"""
Base.close

"""
    Base.show(io::IO, browser::AbstractBrowser)

Displays information about the browser instance.
"""
Base.show

"""
    Base.close(context::AbstractBrowserContext)

Closes the browser context and all its associated pages.
"""
Base.close

"""
    Base.show(io::IO, context::AbstractBrowserContext)

Displays information about the browser context.
"""
Base.show

"""
    Base.close(page::AbstractPage)

Closes the page and cleans up associated resources.
"""
Base.close

"""
    Base.show(io::IO, page::AbstractPage)

Displays information about the page.
"""
Base.show

"""
    Base.close(element::AbstractElementHandle)

Cleans up resources associated with the element handle.
"""
Base.close

"""
    Base.show(io::IO, element::AbstractElementHandle)

Displays information about the element handle.
"""
Base.show
