# PublicLib Swift Submodule Update

- Date: 2026-01-26
- Change: updated `code/mono/.gitmodules` to point PublicLib Swift at the Swift Universal org.
- New URL: https://github.com/swift-universal/swift-public-brokerage-lib.git
- Previous org: wrkstrm
-
- DocC: updated `public-lib-docc.yml` to deploy to GitHub Pages and set
  `--hosting-base-path swift-public-brokerage-lib` for the repo URL.
- DocC: added `workflow_dispatch` and `swift-actions/setup-swift@v2` (Swift 6.2) for
  reliable Ubuntu builds.

## Follow-up (manual)

After syncing, the superproject should update submodule config:

```bash
git submodule sync -- orgs/wrkstrm-finance/private/spm/universal/domain/finance/swift-public-brokerage-lib
```

If needed, refresh the working tree:

```bash
git submodule update --init --recursive orgs/wrkstrm-finance/private/spm/universal/domain/finance/swift-public-brokerage-lib
```
