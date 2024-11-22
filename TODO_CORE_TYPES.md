# Core Types Implementation Plan

## 1. Browser
- [ ] Define Browser struct with WebSocket connection and contexts field
- [ ] Implement Base methods (show, etc.)
- [ ] Unit tests for Base methods
- [ ] Implementation functions:
  - [ ] launch_browser
  - [ ] close_browser
  - [ ] contexts
  - [ ] new_context

## 2. BrowserContext
- [ ] Define BrowserContext struct with browser reference and pages field
- [ ] Implement Base methods
- [ ] Unit tests for Base methods
- [ ] Implementation functions:
  - [ ] new_page
  - [ ] pages
  - [ ] close_context

## 3. Page
- [ ] Define Page struct with context reference and page ID
- [ ] Implement Base methods
- [ ] Unit tests for Base methods
- [ ] Implementation functions:
  - [ ] goto
  - [ ] evaluate
  - [ ] wait_for_selector
  - [ ] query_selector
  - [ ] query_selector_all
  - [ ] click
  - [ ] type_text
  - [ ] screenshot
  - [ ] content
  - [ ] close_page

## 4. ElementHandle
- [ ] Define ElementHandle struct with page reference and element ID
- [ ] Implement Base methods
- [ ] Unit tests for Base methods
- [ ] Implementation functions:
  - [ ] click
  - [ ] type_text
  - [ ] check
  - [ ] uncheck
  - [ ] select_option
  - [ ] is_visible
  - [ ] get_text
  - [ ] get_attribute
  - [ ] evaluate_handle

## Implementation Order
1. Browser (foundational type)
2. BrowserContext (depends on Browser)
3. Page (depends on BrowserContext)
4. ElementHandle (depends on Page)

## Notes
- Each type will need proper constructors
- Need to implement proper error types
- Need to implement timeout functionality across all relevant methods
- Each type should have proper cleanup/finalizer methods
