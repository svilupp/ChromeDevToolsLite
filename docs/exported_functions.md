# Exported Functions and Types

## Types
- WSClient
- ElementHandle
- ElementNotFoundError
- NavigationError
- EvaluationError
- TimeoutError
- ConnectionError

## Utility Functions
- extract_cdp_result
- extract_element_result
- with_retry

## WebSocket Operations
- connect!
- send_cdp_message
- close
- handle_event
- is_connected
- try_connect

## Browser Operations
- connect_browser
- ensure_browser_available

## Page Operations
- goto
- evaluate
- screenshot
- content

## Element Operations
- click
- type_text
- check
- uncheck
- select_option
- is_visible
- get_text
- get_attribute
- evaluate_handle
