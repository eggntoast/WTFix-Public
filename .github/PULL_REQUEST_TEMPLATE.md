## Summary

Describe the problem being addressed and the proposed change.

## Basis

- WTFix version:
- Operating system / platform:
- WoW Forever client/build:
- Related issue:

## Validation

Describe exactly what was tested.

Keep these evidence types separate when relevant:

- source/static checks
- host/test-harness checks
- native WoW client checks
- package/hash verification

## Recovery safety

Confirm that the change preserves the relevant WTFix invariants:

- [ ] Save Snapshot remains the explicit trust/adoption boundary.
- [ ] Later writes do not silently replace the trusted checkpoint.
- [ ] Unsafe or ambiguous recovery states fail closed instead of guessing.
- [ ] Recovery still occurs early enough to protect addons before they initialize.
- [ ] Runtime and preparation-owned WTFix_Data responsibilities remain separate.
- [ ] SavedVariables preparation remains byte-preserving.

## Public export note

WTFix-Public is a curated source export. An accepted change may be integrated into the canonical implementation first and then exported back here rather than merged verbatim.
