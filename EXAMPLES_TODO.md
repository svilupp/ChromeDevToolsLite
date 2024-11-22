# Examples Testing Checklist

## 01_browser_launch.jl
- [ ] Launch browser successfully
- [ ] Create browser context
- [ ] Create new page
- [ ] Navigate to example.com
- [ ] Clean up resources properly

## 02_page_navigation.jl
- [ ] Navigate to page successfully
- [ ] Wait for load state
- [ ] Get page title correctly
- [ ] Get current URL correctly
- [ ] Clean up resources

## 03_page_interaction.jl
- [ ] Navigate to form page
- [ ] Find form element
- [ ] Type text into input field
- [ ] Click submit button
- [ ] Wait for navigation after submit
- [ ] Clean up resources

## 04_element_handling.jl
- [ ] Find multiple elements
- [ ] Get text content from elements
- [ ] Check element visibility
- [ ] Get element attributes
- [ ] Clean up resources

## 05_error_handling.jl
- [ ] Handle timeout error correctly
- [ ] Handle element not found error
- [ ] Clean up resources

## 06_screenshots.jl
- [ ] Take full page screenshot
- [ ] Take element screenshot
- [ ] Verify screenshot files created
- [ ] Clean up resources

Notes:
- Each example should be run with Chromium in debug mode
- Verify actual functionality, not just script execution
- Check for proper error handling
- Ensure resources are cleaned up after each run
