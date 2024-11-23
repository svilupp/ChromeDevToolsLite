using Base.Filesystem

# Files to keep (our new minimal examples)
keep_files = [
    "README.md",
    "TODO.md",
    "simple_connection.jl",
    "navigation_basic.jl",
    "element_basic.jl",
    "form_basic.jl",
    "evaluate_basic.jl",
    "content_basic.jl",
    "screenshot_basic.jl",
    "minimal_core_demo.jl"
]

# Move everything else to archive
for file in readdir("examples")
    if !(file in keep_files)
        src_path = joinpath("examples", file)
        dst_path = joinpath("archive/examples", file)
        if isfile(src_path)
            mv(src_path, dst_path, force=true)
            println("Moved: $file")
        end
    end
end

println("\nCleanup completed! Only minimal examples remain.")
