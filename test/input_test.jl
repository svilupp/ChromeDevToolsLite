using Test
using ChromeDevToolsLite

@testset "Input Control Tests" begin
    client = connect_browser()

    @testset "Mouse Control" begin
        # Test mouse movement
        move_mouse(client, 100, 100)
        pos = get_mouse_position(client)
        @test pos.x ≈ 100
        @test pos.y ≈ 100

        # Test click variations
        @test_nowarn click(client)
        @test_nowarn click(client, button="right")
        @test_nowarn click(client, modifiers=["Shift"])
        @test_nowarn dblclick(client)
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
