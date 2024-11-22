# Page

```@docs
Page
```

The `Page` type represents a single page/tab in the Chrome browser. It is a simple struct that holds the page's ID, URL, and title.

## Examples

```julia
# Example of working with a Page
browser = connect_browser()

# Get all pages and print their information
pages = get_pages(browser)
for page in pages
    println("Page ID: $(page.id)")
    println("URL: $(page.url)")
    println("Title: $(page.title)")
end
```

## Fields

- `id::String`: The unique identifier for the page
- `url::String`: The current URL of the page
- `title::String`: The current title of the page
