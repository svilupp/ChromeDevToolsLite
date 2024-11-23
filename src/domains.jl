"""
    enable_page_domain(client::ChromeClient) -> Dict

Enable the Page domain for navigation and screenshots.
"""
function enable_page_domain(client::ChromeClient)
    send_cdp_message(client, Dict(
        "method" => "Page.enable",
        "params" => Dict()
    ))
end

"""
    enable_runtime_domain(client::ChromeClient) -> Dict

Enable the Runtime domain for JavaScript evaluation.
"""
function enable_runtime_domain(client::ChromeClient)
    send_cdp_message(client, Dict(
        "method" => "Runtime.enable",
        "params" => Dict()
    ))
end
