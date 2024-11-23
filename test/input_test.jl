using Test
using ChromeDevToolsLite

@testset "Input Control Tests" begin
    client = connect_browser()
    # Use a simple HTML page with minimal content
    goto(client, "data:text/html,<div id='test-div' style='position:fixed;left:100px;top:100px;width:50px;height:50px;'>Test Div</div>")

    @testset "Mouse Control" begin
        # Test element position
        pos = get_element_position(client, "#test-div")
        @test pos.x ≈ 125  # 100 + width/2
        @test pos.y ≈ 125  # 100 + height/2

        # Test mouse movement and position
        move_mouse(client, pos.x, pos.y)
        current_pos = get_mouse_position(client)
        @test current_pos.x ≈ pos.x
        @test current_pos.y ≈ pos.y

        # Test click variations
        @test_nowarn click(client, x=pos.x, y=pos.y)
        @test_nowarn click(client, button="right", x=pos.x, y=pos.y)
        @test_nowarn click(client, x=pos.x, y=pos.y, modifiers=["Shift"])
        @test_nowarn dblclick(client, x=pos.x, y=pos.y)
    end

    @testset "Keyboard Control" begin
        # Test basic key press
        @test_nowarn press_key(client, "a")
        @test_nowarn press_key(client, "Enter")

        # Test modifier keys
        @test_nowarn press_key(client, "a", modifiers=["Control"])
        @test_nowarn press_key(client, "c", modifiers=["Control", "Shift"])

        # Test text typing
        @test_nowarn type_text(client, "Hello, World!")
    end

    close(client)
end
