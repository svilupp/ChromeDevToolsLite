using ChromeDevToolsLite
using Test

@testset "ChromeDevToolsLite Basic Tests" begin
    @testset "WebSocket Connection" begin
        # Basic connection test
        @test isdefined(ChromeDevToolsLite, :connect_browser)
    end

    @testset "CDP Commands" begin
        # Basic CDP command functionality
        @test isdefined(ChromeDevToolsLite, :send_cdp_message)
    end

    @testset "Page Operations" begin
        # Basic page operations
        @test isdefined(ChromeDevToolsLite, :goto)
        @test isdefined(ChromeDevToolsLite, :evaluate)
    end

    @testset "Element Operations" begin
        # Basic element operations
        @test isdefined(ChromeDevToolsLite, :click)
        @test isdefined(ChromeDevToolsLite, :type_text)
    end

    @testset "Screenshots" begin
        # Screenshot functionality
        @test isdefined(ChromeDevToolsLite, :screenshot)
    end
end
