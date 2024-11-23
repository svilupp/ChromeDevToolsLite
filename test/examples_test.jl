using Test
using ChromeDevToolsLite
using HTTP
using JSON3
using Base64

@testset "Example Scripts" begin
    # Setup Chrome connection
    response = HTTP.get("http://localhost:9222/json")
    targets = JSON3.read(response.body)
    target = first(filter(t -> t.type == "page", targets))
    client = connect_chrome(target.webSocketDebuggerUrl)

    @testset "minimal_connection.jl" begin
        result = send_cdp_message(client, Dict("method" => "Browser.getVersion"))
        @test haskey(result.result, :product)
        @test haskey(result.result, :protocolVersion)
    end

    @testset "minimal_cdp.jl" begin
        # Test Browser info
        result = send_cdp_message(client, Dict("method" => "Browser.getVersion"))
        @test haskey(result.result, :product)

        # Test domain enabling
        for domain in ["Page", "Runtime", "DOM"]
            result = send_cdp_message(client, Dict("method" => "$(domain).enable"))
            @test !haskey(result, :error)
        end
    end

    @testset "navigation.jl" begin
        # Test navigation
        result = send_cdp_message(client, Dict(
            "method" => "Page.navigate",
            "params" => Dict("url" => "https://example.com")
        ))
        @test haskey(result.result, :loaderId)

        # Test URL verification
        result = send_cdp_message(client, Dict(
            "method" => "Runtime.evaluate",
            "params" => Dict(
                "expression" => "window.location.href",
                "returnByValue" => true
            )
        ))
        @test result.result.result.value == "https://example.com/"
    end

    @testset "evaluate.jl" begin
        # Test basic evaluation
        result = send_cdp_message(client, Dict(
            "method" => "Runtime.evaluate",
            "params" => Dict(
                "expression" => "2 + 2",
                "returnByValue" => true
            )
        ))
        @test result.result.result.value == 4

        # Test DOM query
        result = send_cdp_message(client, Dict(
            "method" => "Runtime.evaluate",
            "params" => Dict(
                "expression" => "document.querySelector('html').tagName",
                "returnByValue" => true
            )
        ))
        @test result.result.result.value == "HTML"
    end

    @testset "screenshot.jl" begin
        # Test full page screenshot
        result = send_cdp_message(client, Dict(
            "method" => "Page.captureScreenshot",
            "params" => Dict("format" => "png")
        ))
        @test haskey(result.result, :data)
        @test length(base64decode(result.result.data)) > 0
    end

    @testset "element_interaction.jl" begin
        # Test element creation and interaction
        result = send_cdp_message(client, Dict(
            "method" => "Runtime.evaluate",
            "params" => Dict(
                "expression" => """
                const btn = document.createElement('button');
                btn.textContent = 'Test';
                document.body.appendChild(btn);
                btn.textContent
                """,
                "returnByValue" => true
            )
        ))
        @test result.result.result.value == "Test"
    end

    # Cleanup
    close(client)
end
