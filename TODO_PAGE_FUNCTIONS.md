# Page Functions Testing Todo List

## Core Navigation
- [ ] goto(page, url)
  - Verify successful navigation
  - Check page title and URL
  - Test timeout handling
  - Test invalid URL handling

## Page Content
- [ ] content()
  - Get page HTML content
  - Verify content matches expected
  - Test with dynamic content

## Screenshots
- [ ] screenshot()
  - Full page screenshot
  - Element screenshot
  - Verify file output
  - Test different formats

## DOM Interaction
- [ ] query_selector()
  - Find single element
  - Test non-existent selector
  - Test timeout behavior
- [ ] query_selector_all()
  - Find multiple elements
  - Count elements
  - Iterate over elements
- [ ] is_visible()
  - Check element visibility
  - Test hidden elements
  - Test display:none elements

## Element State
- [ ] wait_for_selector()
  - Wait for element to appear
  - Test timeout behavior
  - Test element removal

## Testing Strategy
1. Create simple HTML pages for testing
2. Implement example for each function
3. Add verification steps in examples
4. Test error conditions
5. Document behavior

## Example Files to Create
1. examples/page_navigation_test.jl
2. examples/page_content_test.jl
3. examples/screenshot_test.jl
4. examples/selector_test.jl
5. examples/visibility_test.jl

## Test HTML Pages Needed
1. static_test.html - Simple static content
2. dynamic_test.html - Content that changes
3. form_test.html - Interactive elements
4. visibility_test.html - Various visibility states
