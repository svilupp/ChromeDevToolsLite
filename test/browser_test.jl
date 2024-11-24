using Test
using ChromeDevToolsLite

const ENDPOINT = "http://localhost:9222"

@testset "Browser and Page Tests" begin
    client = connect_browser(ENDPOINT)

    @testset "Client Structure" begin
        @test client isa WSClient
        @test !isempty(client.ws_url)
        @test client.is_connected
        page = get_page(client)
        @test page isa Page
        @test !isempty(page.target_id)
    end

    @testset "Page Navigation" begin
        # Test page navigation with local file
        local_path = joinpath(@__DIR__, "test_pages", "form.html")
        url = "file://" * local_path

        # Test goto with client
        @test goto(client, url) === nothing

        # Test page info after navigation
        page = get_page(client)
        page_info = get_page_info(page)
        @test haskey(page_info, "url")
        @test page_info["url"] == url

        # Test content after navigation
        html_content = content(client)
        @test html_content isa String
        @test occursin("<form", html_content)
    end

    @testset "Page Operations" begin
        # Test screenshot
        screenshot_data = screenshot(client)
        @test screenshot_data isa String
        @test !isempty(screenshot_data)

        # Test JavaScript evaluation
        result = evaluate(client, "document.title")
        @test result isa String
    end

    # Clean up
    close(client)
end
