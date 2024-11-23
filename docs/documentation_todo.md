# Documentation Cleanup Todo List

## Files to Remove
- docs/src/contributing.md (remove completely)
- docs/src/error_types.md (remove completely)

## Files to Consolidate
- All API documentation files to be merged into one file:
  - docs/src/api/browser.md
  - docs/src/api/cdp.md
  - docs/src/api/element.md
  - docs/src/api/page.md
  - docs/src/api/utilities.md
  -> Will be consolidated into: docs/src/api.md

## Files to Update
- docs/src/examples.md (needs testing and verification)
- docs/src/getting_started.md (needs review against current exports)
- docs/src/index.md (may need updates after consolidation)

## Steps
1. Remove unnecessary files
2. Create new consolidated API documentation
3. Test and verify all examples
4. Update getting started guide
5. Update index page
6. Review cross-references between files
