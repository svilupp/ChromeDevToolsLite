"""
    count_elements(page::AbstractPage, selector::String)

Count the number of elements matching the given CSS selector.
"""
function count_elements(page::AbstractPage, selector::String)
    result = evaluate(page, """
    (function() {
        return document.querySelectorAll('$(selector)').length;
    })()
    """)

    return result["result"]["value"]
end

"""
    is_visible(page::AbstractPage, selector::String)

Check if an element matching the selector is visible.
"""
function is_visible(page::AbstractPage, selector::String)
    result = evaluate(page, """
    (function() {
        const element = document.querySelector('$(selector)');
        if (!element) return false;

        const style = window.getComputedStyle(element);
        return style.display !== 'none' &&
               style.visibility !== 'hidden' &&
               style.opacity !== '0';
    })()
    """)

    return result["result"]["value"]
end

"""
    get_text(page::AbstractPage, selector::String)

Get the text content of the first element matching the selector.
"""
function get_text(page::AbstractPage, selector::String)
    result = evaluate(page, """
    (function() {
        const element = document.querySelector('$(selector)');
        return element ? element.textContent.trim() : null;
    })()
    """)

    return result["result"]["value"]
end

"""
    query_selector_all(page::AbstractPage, selector::String)

Get all elements matching the selector.
"""
function query_selector_all(page::AbstractPage, selector::String)
    result = evaluate(page, """
    (function() {
        const elements = Array.from(document.querySelectorAll('$(selector)'));
        return elements.map((el, index) => ({
            nodeId: index,
            text: el.textContent.trim()
        }));
    })()
    """)

    return result["result"]["value"]
end

export count_elements, is_visible, get_text, query_selector_all
