using ChromeDevToolsLite
using Test
using Aqua

@testset "ChromeDevToolsLite.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ChromeDevToolsLite)
    end
    # Write your tests here.
end
