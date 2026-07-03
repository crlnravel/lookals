# Lookals

## Local signing setup

Each developer should keep their Apple Developer Team ID outside the committed
Xcode project.

After cloning, the easiest setup is to point the script at an existing Xcode
project that already builds on your machine:

```sh
./scripts/setup-signing.sh --from-project /path/to/WorkingLookals.xcodeproj
```

The script reads that project's concrete `DEVELOPMENT_TEAM` and
`PRODUCT_BUNDLE_IDENTIFIER` values, then writes them into this checkout's
ignored local signing config.

You can also run the script interactively:

```sh
./scripts/setup-signing.sh
```

Or pass values explicitly:

```sh
./scripts/setup-signing.sh ABCDE12345 appledev.yourname.Lookals
```

### Finding the values

The Apple Developer Team ID is the 10-character ID for the Apple account or team
that Xcode uses for signing. You can find it in Xcode under **Settings >
Accounts**, then select your Apple ID and team. It is also shown in the Apple
Developer account membership details.

If Xcode does not show the raw ID in the Accounts screen, the selected team is
still written into the build setting named `DEVELOPMENT_TEAM`. In this project,
that value is read through `LOOKALS_DEVELOPMENT_TEAM` from
`Config/Signing.local.xcconfig`.

The setup script can copy the value from an existing working Xcode project, which
is usually simpler than finding it manually:

```sh
./scripts/setup-signing.sh --from-project /path/to/WorkingApp.xcodeproj
```

To check what Xcode is resolving locally, run:

```sh
xcodebuild -project Lookals.xcodeproj -scheme Lookals -configuration Debug -showBuildSettings | grep DEVELOPMENT_TEAM
```

The code-signing certificate list in Keychain can be useful, but treat Xcode's
selected signing team as the source of truth for this project.

The local bundle identifier should be unique to the developer's Apple account,
especially when using a personal team. A good format is:

```text
appledev.name.Lookals
```

We used `RVQGL2GL8J` and `appledev.Lookals` for this checkout because those were
the values already stored in `Lookals.xcodeproj/project.pbxproj` before signing
was moved into local config.

When no values are passed, the setup script tries to choose defaults in this
order:

1. `LOOKALS_DEVELOPMENT_TEAM` and `LOOKALS_BUNDLE_IDENTIFIER` environment
   variables.
2. Existing values in `Config/Signing.local.xcconfig`.
3. A previous hard-coded `DEVELOPMENT_TEAM` in the Xcode project, if present.
4. A single Apple Development signing identity found in the local keychain.
5. The shared bundle identifier from `Config/Signing.xcconfig`.

The script writes `Config/Signing.local.xcconfig`, which is ignored by git, and
configures the repo to use `.githooks/pre-commit` as a guard against committing
a personal `DEVELOPMENT_TEAM` back into `project.pbxproj`.
