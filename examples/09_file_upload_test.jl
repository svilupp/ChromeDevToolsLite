using ChromeDevToolsLite

# Start browser and navigate to test page
browser = Browser()
context = create_browser_context(browser)
page = create_page(context)

# Create a test HTML file with file upload form
html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>File Upload Test</title>
</head>
<body>
    <form id="upload-form">
        <div>
            <label for="file">Choose file:</label>
            <input type="file" id="file" name="file">
        </div>
        <button type="submit">Upload</button>
    </form>
    <div id="upload-result"></div>

    <script>
        document.getElementById('upload-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const file = document.getElementById('file').files[0];
            const result = file ?
                'Selected file: ' + file.name + ' (type: ' + file.type + ', size: ' + file.size + ' bytes)' :
                'No file selected';
            document.getElementById('upload-result').textContent = result;
        });
    </script>
</body>
</html>
"""

# Create a test file to upload
test_content = "This is a test file content"
test_upload_file = joinpath(@__DIR__, "..", "test", "test_pages", "test_upload.txt")
write(test_upload_file, test_content)

# Create and navigate to the test page
test_page = joinpath(@__DIR__, "..", "test", "test_pages", "file_upload.html")
write(test_page, html_content)
goto(page, "file://" * test_page)

# Set file input
set_file_input_files(page, "#file", [test_upload_file])

# Submit the form
click(page, "button[type=\"submit\"]")

# Wait a moment for the submission to process
sleep(0.5)

# Verify upload result
result_text = get_text(page, "#upload-result")
@assert contains(result_text, "test_upload.txt") "File name not found in result"
@assert contains(result_text, "text/plain") "File type not found in result"
@assert contains(result_text, string(length(test_content))) "File size not correct"

println("✓ File upload test successful")

# Clean up
close(browser)
rm(test_page)
rm(test_upload_file)
