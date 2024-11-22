using ChromeDevToolsLite
using Test
using Aqua
push!(LOAD_PATH, joinpath(@__DIR__, "TestUtils/src"))
using TestUtils

@testset "ChromeDevToolsLite.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ChromeDevToolsLite)
    end

    @testset "CDP" begin
        include("cdp/test_messages.jl")
        include("cdp/test_session.jl")
    end

    @testset "Browser" begin
        include("browser/test_process.jl")
    end

    @testset "Core Types" begin
        include("types/test_browser.jl")
        include("types/test_browser_context.jl")
        include("types/test_page.jl")
        include("types/test_element_handle.jl")
    end
end
