@testset "types.jl" begin
    # Test WSClient constructor and show
    @test WSClient("ws://test").ws_url == "ws://test"
    @test WSClient("ws://test").is_connected == false
    @test WSClient("ws://test", "endpoint").endpoint == "endpoint"

    client = WSClient("ws://example.com")
    @test sprint(show, client) == "WSClient(url: ws://example.com)"

    # Test Page constructor and show
    test_client = WSClient("ws://test.com")
    test_page = Page(client = test_client, target_id = "123", extras = Dict{String, Any}())
    @test test_page.target_id == "123"
    @test test_page.client === test_client

    # Test Page show with empty URL
    @test sprint(show, test_page) == "Page(id: 123, url: -)"

    # Test Page show with URL
    page_with_url = Page(
        client = test_client,
        target_id = "123",
        extras = Dict("url" => "https://example.com")
    )
    @test sprint(show, page_with_url) == "Page(id: 123, url: https://example.com)"

    # Test Page is_active
    @test is_active(test_page) == false
    active_page = Page(
        client = test_client,
        target_id = "123",
        extras = Dict("attached" => true)
    )
    @test is_active(active_page) == true

    # Test ElementHandle constructor and show
    eh = ElementHandle(test_client, "#selector")
    @test eh.selector == "#selector"
    @test eh.verbose == false
    @test sprint(show, eh) == "ElementHandle(selector: #selector)"

    # Test ElementHandle from Page
    eh_from_page = ElementHandle(test_page, "#selector")
    @test eh_from_page.selector == "#selector"
    @test eh_from_page.client === test_client

    # Test custom errors
    @test try
        throw(ElementNotFoundError("div"))
    catch e
        e.message == "Element not found: div"
    end

    @test try
        throw(NavigationError("http://test.com"))
    catch e
        e.message == "Navigation failed: http://test.com"
    end

    @test try
        throw(EvaluationError("console.log(1)"))
    catch e
        e.message == "Evaluation failed\nScript: console.log(1)"
    end

    @test try
        throw(TimeoutError("Custom timeout"))
    catch e
        e.message == "Custom timeout"
    end

    @test try
        throw(ConnectionError("Custom error"))
    catch e
        e.message == "Custom error"
    end
end
