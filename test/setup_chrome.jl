using Pkg

"""
    setup_chrome()

Sets up Chrome for testing on Linux systems. Throws an error on non-Linux systems
indicating that users need to start Chrome manually in debug mode.
"""
function setup_chrome()
    if Sys.islinux()
        # Check if Chrome is installed
        chrome_installed = try
            success(`which google-chrome`)
        catch
            false
        end

        if !chrome_installed
            @info "Installing Chrome on Linux..."
            run(`sudo apt-get update`)
            run(`sudo apt-get install -y google-chrome-stable`)
        end

        # Start Chrome in debug mode
        try
            run(`pkill chrome`)
            sleep(1)
        catch
            # Chrome wasn't running, which is fine
        end

        cmd = pipeline(`google-chrome --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, stdout=devnull, stderr=devnull)
        process = run(cmd, wait=false)
        sleep(5)  # Give Chrome time to start

        # Verify Chrome is running
        for _ in 1:3
            try
                HTTP.get("http://localhost:9222/json/version")
                return true
            catch
                sleep(2)
            end
        end
        error("Failed to start Chrome in debug mode")
    else
        error("""
        Chrome must be started manually in debug mode on non-Linux systems.
        Please start Chrome with the following flags:
        --remote-debugging-port=9222 --headless --disable-gpu
        """)
    end
end

export setup_chrome
