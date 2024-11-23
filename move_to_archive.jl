using Base.Filesystem

# Create archive directories if they don't exist
mkpath("archive/examples")
mkpath("archive/src")
mkpath("archive/test")

# List of complex examples to move
complex_examples = [
    "form_interaction.jl",
    "visibility_test.jl",
    "test_targets.jl",
    "checkbox_test.jl",
    "debug_connection.jl",
    "test_connection.jl",
    "debug_websocket.jl",
    "test_http_endpoint.jl",
    "test_chrome_python.py",
    "test_websocket.jl",
    "test_cdp_commands.jl",
    "test_targets.jl",
    "form_interaction_test.jl",
    "minimal_example.jl",
    "form_example.jl",
    "form_test.jl",
    "minimal_connection.jl",
    "minimal_cdp.jl",
    "element_test.jl",
    "screenshot_test.jl",
    "simple_connection_test.jl",
    "element_interaction_test.jl",
    "connection_debug.jl",
    "evaluate_test.jl",
    "select_test.jl",
    "click_test.jl"
]

# Move complex examples
for example in complex_examples
    src_path = joinpath("examples", example)
    dst_path = joinpath("archive/examples", example)
    if isfile(src_path)
        mv(src_path, dst_path, force=true)
        println("Moved: $example")
    end
end

println("\nArchiving completed!")
