using ChromeDevToolsLite

# Connect to Chrome
client = connect_chrome(get_ws_url())
println("Connected to Chrome")

# Create a test form page
println("\nCreating test form...")
goto(client, "about:blank")
evaluate(client, """
    document.body.innerHTML = `
        <form id="userForm" style="padding: 20px;">
            <input type="text" id="username" placeholder="Username"><br>
            <input type="email" id="email" placeholder="Email"><br>
            <textarea id="message" placeholder="Message"></textarea><br>
            <button type="submit" id="submit">Submit</button>
        </form>
        <div id="result"></div>
    `;

    document.getElementById('userForm').onsubmit = (e) => {
        e.preventDefault();
        const result = {
            username: document.getElementById('username').value,
            email: document.getElementById('email').value,
            message: document.getElementById('message').value
        };
        document.getElementById('result').textContent = JSON.stringify(result, null, 2);
    };
""")

# Fill out the form
println("\nFilling out form...")
type_text(client, "#username", "testuser")
type_text(client, "#email", "test@example.com")
type_text(client, "#message", "Hello from Julia!")

# Submit form
println("\nSubmitting form...")
click_element(client, "#submit")

# Get results
println("\nForm submission result:")
result = evaluate(client, "document.getElementById('result').textContent")
println(result)

# Clean up
close(client)
println("\nConnection closed.")
