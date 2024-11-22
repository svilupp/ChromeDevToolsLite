using Test
using ChromeDevToolsLite
using HTTP

@testset "Browser Process Management" begin
    @testset "Browser Launch" begin
        # Test browser process launch with default options
        process = launch_browser_process()
        @test process.pid > 0
        @test startswith(process.endpoint, "http://localhost:")
        @test process.options["headless"] == true

        # Verify browser is responding
        response = HTTP.get("$(process.endpoint)/json/version")
        @test response.status == 200
        version_info = JSON3.read(response.body)
        @test haskey(version_info, "Browser")
        @test haskey(version_info, "Protocol-Version")

        # Clean up
        kill_browser_process(process)
        sleep(0.1)  # Give process time to terminate
        @test_throws Base.ProcessFailedException run(`ps -p $(process.pid)`)
    end

    @testset "Browser Launch Options" begin
        # Test with specific port
        port = 9222
        process = launch_browser_process(port=port)
        @test process.endpoint == "http://localhost:$port"
        kill_browser_process(process)

        # Test non-headless mode
        process = launch_browser_process(headless=false)
        @test process.options["headless"] == false
        kill_browser_process(process)
    end

    @testset "Error Handling" begin
        # Test invalid port (should automatically find another port)
        process = launch_browser_process(port=1)  # Port 1 should be invalid
        @test process.pid > 0  # Should still launch successfully
        @test process.endpoint != "http://localhost:1"
        kill_browser_process(process)
    end
end
