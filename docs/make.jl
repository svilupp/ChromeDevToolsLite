using ChromeDevToolsLite
using Documenter

DocMeta.setdocmeta!(ChromeDevToolsLite, :DocTestSetup, :(using ChromeDevToolsLite); recursive=true)

makedocs(;
    modules=[ChromeDevToolsLite],
    authors="J S <49557684+svilupp@users.noreply.github.com> and contributors",
    sitename="ChromeDevToolsLite.jl",
    format=Documenter.HTML(;
        canonical="https://svilupp.github.io/ChromeDevToolsLite.jl",
        edit_link="main",
        assets=String[],
    ),
    warnonly=[:missing_docs, :docs_block],
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Examples" => "examples.md",
        "API Reference" => "api/reference.md",
        "Guides" => [
            "HTTP Capabilities" => "guides/http_capabilities.md",
            "HTTP Limitations" => "guides/http_limitations.md",
            "Troubleshooting" => "guides/troubleshooting.md",
            "Migration" => "guides/migration.md"
        ]
    ],
    source="src",
    build="build",
    clean=true,  # Clean build directory
    doctest=true,
)

deploydocs(;
    repo="github.com/svilupp/ChromeDevToolsLite.jl",
    devbranch="main",
)
