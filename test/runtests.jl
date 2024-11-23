using ChromeDevToolsLite
using Test

@testset "ChromeDevToolsLite.jl" begin
    @testset "Basic Functionality" begin
        include("basic_test.jl")
    end
end
