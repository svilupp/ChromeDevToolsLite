# Abstract types
"""
    AbstractBrowser

Base type for browser instances. Supports the following Base operations:
- `Base.close(browser)`: Closes the browser and cleans up resources
- `Base.show(io::IO, browser)`: Displays browser information
"""
abstract type AbstractBrowser end

"""
    AbstractBrowserContext

Base type for browser contexts. Supports the following Base operations:
- `Base.close(context)`: Closes the context and all its pages
- `Base.show(io::IO, context)`: Displays context information
"""
abstract type AbstractBrowserContext end

"""
    AbstractPage

Base type for browser pages. Supports the following Base operations:
- `Base.close(page)`: Closes the page and cleans up resources
- `Base.show(io::IO, page)`: Displays page information
"""
abstract type AbstractPage end

"""
    AbstractElementHandle

Base type for DOM element handles. Supports the following Base operations:
- `Base.close(element)`: Cleans up element resources
- `Base.show(io::IO, element)`: Displays element information
"""
abstract type AbstractElementHandle end

# Export abstract types
export AbstractBrowser, AbstractBrowserContext, AbstractPage, AbstractElementHandle
