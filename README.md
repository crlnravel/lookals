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
./scripts/setup-signing.sh ABCDE12345 com.yourname.Lookals
```

The script writes `Config/Signing.local.xcconfig`, which is ignored by git, and
configures the repo to use `.githooks/pre-commit` as a guard against committing
a personal `DEVELOPMENT_TEAM` back into `project.pbxproj`.
