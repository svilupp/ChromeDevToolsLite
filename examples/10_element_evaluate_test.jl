using ChromeDevToolsLite
using Test

# Create a simple test HTML file
html_content = """
<!DOCTYPE html>
<html>
<body>
    <div id="test-div">Test Content</div>
</body>
</html>
"""

# Write the test HTML to a file
test_dir = joinpath(dirname(@__FILE__), "test_pages")
mkpath(test_dir)
test_file = joinpath(test_dir, "element_evaluate.html")
write(test_file, html_content)

try
    # Start browser and navigate to test page
    browser = launch_browser()
    page = new_page(new_context(browser))
    file_url = "file://$(abspath(test_file))"

    @info "Navigating to test page..."
    goto(page, file_url)
    sleep(1)

    # Basic element test
    @info "Testing basic element evaluation..."
    div = query_selector(page, "#test-div")
    @test !isnothing(div)

    text_content = evaluate_handle(div, "el => el.textContent")
    @test text_content == "Test Content"
    println("✓ Basic element evaluation test passed")

finally
    @info "Cleaning up..."
    try
        close(browser)
    catch e
        @warn "Error during browser cleanup" exception=e
    end
    try
        rm(test_file)
    catch e
        @warn "Error removing test file" exception=e
    end
end
