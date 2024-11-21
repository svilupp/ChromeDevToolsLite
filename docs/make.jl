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
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/svilupp/ChromeDevToolsLite.jl",
    devbranch="main",
)
