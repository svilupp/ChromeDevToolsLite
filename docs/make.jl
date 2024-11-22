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
    warnonly=[:missing_docs],
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "API Reference" => "api/browser.md",
    ],
    source="src",
    build="build",
    clean=true,  # Clean build directory
    doctest=true,
    checkdocs=:all,
)

deploydocs(;
    repo="github.com/svilupp/ChromeDevToolsLite.jl",
    devbranch="main",
)
