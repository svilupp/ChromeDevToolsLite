using Test
using ChromeDevToolsLite

@testset "Page Management Tests" begin
    client = connect_browser("http://localhost:9222")

    @testset "Page Creation and Info" begin
        # Test new page creation
        page = new_page(client)
        @test page isa Page
        @test !isempty(page.target_id)

        # Test get all pages
        pages = get_all_pages(client)
        @test pages isa Vector{Page}
        @test length(pages) ≥ 1
        @test any(p -> p.target_id == page.target_id, pages)

        # Test page info and metadata
        info = get_page_info(page)
        @test info isa Dict{String,Any}
        @test haskey(info, "url")
        @test info["url"] == "about:blank"

        # Test viewport management
        viewport = get_viewport(page)
        @test viewport isa Dict{String,Any}

        # Test viewport setting
        set_viewport(page; width=1024, height=768)
        new_viewport = get_viewport(page)
        @test haskey(new_viewport, "layoutViewport")
        layout = new_viewport["layoutViewport"]
        @test layout["clientWidth"] == 1024
        @test layout["clientHeight"] == 768
    end

    # Clean up
    close(client)
end
