"""
    set_file_input_files(page::Page, selector::AbstractString, files::Vector{AbstractString})

Sets the files to be uploaded in a file input element.
"""
function set_file_input_files(page::Page, selector::AbstractString, files::Vector{AbstractString})
    # Ensure all files exist and are absolute paths
    abs_files = map(files) do file
        if !isfile(file)
            throw(ArgumentError("File not found: $file"))
        end
        return abspath(file)
    end

    # First verify the element exists
    element = query_selector(page, selector)
    if isnothing(element)
        throw(ArgumentError("File input element not found: $selector"))
    end

    # Use JavaScript to verify it's a file input
    js_check = """
    (() => {
        const input = document.querySelector('$(selector)');
        return input && input.type === 'file';
    })()
    """
    is_file_input = evaluate(page, js_check)
    if !is_file_input
        throw(ArgumentError("Element is not a file input: $selector"))
    end

    # Read the file content and encode it
    file_content = Base64.base64encode(read(first(abs_files)))

    # Determine MIME type based on file extension
    ext = lowercase(splitext(first(abs_files))[2])
    mime_type = if ext == ".txt"
        "text/plain"
    elseif ext in [".jpg", ".jpeg"]
        "image/jpeg"
    elseif ext == ".png"
        "image/png"
    elseif ext == ".pdf"
        "application/pdf"
    else
        "application/octet-stream"
    end

    # Set the file input value using JavaScript with actual content
    js_code = """
    (() => {
        const input = document.querySelector('$(selector)');
        const dt = new DataTransfer();
        const content = atob('$file_content');
        const arr = new Uint8Array(content.length);
        for (let i = 0; i < content.length; i++) {
            arr[i] = content.charCodeAt(i);
        }
        const file = new File([arr], '$(basename(first(abs_files)))', { type: '$mime_type' });
        dt.items.add(file);
        input.files = dt.files;
        const event = new Event('change', { bubbles: true });
        input.dispatchEvent(event);
        return true;
    })()
    """
    evaluate(page, js_code)
end

# Convenience method for single file
set_file_input_files(page::Page, selector::AbstractString, file::AbstractString) =
    set_file_input_files(page, selector, [file])
