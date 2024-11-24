@testset "Page Management" begin
    client = connect_browser(ENDPOINT)
    page = get_page(client)

    # Test new page creation
    new_test_page = new_page(client)
    @test new_test_page isa Page
    @test !isempty(new_test_page.target_id)

    # Basic page operations
    @test page isa Page
    @test !isempty(get_target_info(page))

    # Test page info and updates
    update_page!(page)
    @test haskey(page.extras, "targetId")

    goto(client, "about:blank")
    info = get_page_info(page)
    @test haskey(info, "targetId")
    @test haskey(info, "url")
    @test info["url"] == "about:blank"

    # Test multiple pages
    pages = get_all_pages(client)
    @test length(pages) > 0
    @test all(p -> p isa Page, pages)
    @test any(p -> p.target_id == new_test_page.target_id, pages)

    # Viewport management tests
    viewport = get_viewport(page)
    @test viewport isa Dict{String, Any}
    @test haskey(viewport, "layoutViewport")

    set_viewport!(page, width = 1024, height = 768)
    new_viewport = get_viewport(page)
    @test new_viewport["layoutViewport"]["clientWidth"] == 1024
    @test new_viewport["layoutViewport"]["clientHeight"] == 768

    # Element selection tests
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
    el_id = query_selector(page, "#test")
    @test !isnothing(el_id)
    @test el_id isa Integer

    # Test multiple elements selection
    elements = query_selector_all(page, ".para")
    @test length(elements) == 2

    # Test element info
    info = get_element_info(page, "#test")
    @test haskey(info, "nodeId")
    @test info["id"] == "test"
    @test info["tag"] == "DIV"

    # Clean up
    close(client)
end
