using Test
using ChromeDevToolsLite

@testset "Page Management" begin
    client = connect_browser()
    page = get_page(client)

    @testset "Basic Page Operations" begin
        @test page isa Page
        @test !isempty(get_target_info(page))

        # Test page info and updates
        update_page!(page)
        @test haskey(page.extras, "target_info")

        info = get_page_info(page)
        @test haskey(info, "target_info")
        @test !isempty(info["target_info"])
    end

    @testset "Viewport Management" begin
        # Get initial viewport
        viewport = get_viewport(page)
        @test haskey(viewport, "layoutViewport")

        # Set custom viewport
        set_viewport(page, width=1024, height=768)
        new_viewport = get_viewport(page)
        @test new_viewport["layoutViewport"]["clientWidth"] == 1024
        @test new_viewport["layoutViewport"]["clientHeight"] == 768
    end

    @testset "Element Selection" begin
        goto(client, "about:blank")

        # Inject test content
        evaluate(client, """
            document.body.innerHTML = `
                <div id="test">
                    <p class="para">Test paragraph</p>
                    <p class="para">Another paragraph</p>
                </div>
            `;
        """)

        # Test single element selection
        element = query_selector(page, "#test")
        @test !isnothing(element)
        @test haskey(element, "nodeId")

        # Test multiple elements selection
        elements = query_selector_all(page, ".para")
        @test length(elements) == 2

        # Test element info
        info = get_element_info(page, "#test")
        @test haskey(info, "node")
        @test info["node"]["nodeType"] == 1  # Element node
    end

    @testset "Browser Context" begin
        # Test context creation with custom viewport
        context_page = new_context(client,
            viewport=Dict("width" => 1920, "height" => 1080),
            user_agent="Custom User Agent")
        @test context_page isa Page

        viewport = get_viewport(context_page)
        @test viewport["layoutViewport"]["clientWidth"] == 1920
        @test viewport["layoutViewport"]["clientHeight"] == 1080

        # Test multiple pages
        pages = get_all_pages(client)
        @test length(pages) > 0
        @test all(p -> p isa Page, pages)
    end
end
