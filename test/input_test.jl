# @testset "Input Control Tests" begin
client = connect_browser(ENDPOINT)
page = get_page(client)
# Use a simple HTML page with input element and test div
goto(page,
    "data:text/html,<input id='test-input' type='text' style='position:fixed;left:50px;top:50px;'><div id='test-div' style='position:fixed;left:100px;top:100px;width:50px;height:50px;'>Test Div</div>")

@testset "Mouse Control" begin
    # Test element position
    pos = get_element_position(page.client, "#test-div")
    @test pos.x ≈ 125  # 100 + width/2
    @test pos.y ≈ 125  # 100 + height/2

    # Test mouse movement and position
    @test move_mouse(page.client, pos.x, pos.y)
    current_pos = get_mouse_position(page.client)
    @test current_pos.x ≈ pos.x
    @test current_pos.y ≈ pos.y

    # Test click variations
    @test click(page.client, x = pos.x, y = pos.y)
    @test click(page.client, button = "right", x = pos.x, y = pos.y)
    @test click(page.client, x = pos.x, y = pos.y, modifiers = ["Shift"])
    @test dblclick(page.client, x = pos.x, y = pos.y)
end

@testset "Keyboard Control" begin
    # Focus input element
    input_pos = get_element_position(page.client, "#test-input")
    @test click(page.client, x = input_pos.x, y = input_pos.y)

    # Test basic key press
    @test press_key(page.client, "a")
    input_value = evaluate(page.client, "document.getElementById('test-input').value")
    @test input_value == "a"

    # Clear input
    evaluate(page.client, "document.getElementById('test-input').value = ''")

    # Test modifier keys
    @test press_key(page.client, "a", modifiers = ["Control"])  # Should not affect input
    input_value = evaluate(page.client, "document.getElementById('test-input').value")
    @test input_value == ""

    # Test text typing
    @test type_text(page.client, "Hello, World!")
    input_value = evaluate(page.client, "document.getElementById('test-input').value")
    @test input_value == "Hello, World!"
end

close(client)
# end
