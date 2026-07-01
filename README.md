# Lookals

## Local signing setup

Each developer should keep their Apple Developer Team ID outside the committed
Xcode project.

After cloning, run:

```sh
./scripts/setup-signing.sh
```

You can also pass values explicitly:

```sh
./scripts/setup-signing.sh ABCDE12345 appledev.yourname.Lookals
```

### Finding the values

The Apple Developer Team ID is the 10-character ID for the Apple account or team
that Xcode uses for signing. You can find it in Xcode under **Settings >
Accounts**, then select your Apple ID and team. It is also shown in the Apple
Developer account membership details.

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
