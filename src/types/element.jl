"""
    ElementHandle

Represents a reference to a DOM element in the browser.
"""
mutable struct ElementHandle
    page::Page
    node_id::String
    backend_node_id::Int64
    selector::String  # Added selector field to store how we found this element
end
