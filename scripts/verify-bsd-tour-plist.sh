#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/lookals-plist-verification.XXXXXX")"
trap 'rm -rf "$DERIVED_ROOT"' EXIT

build_and_check() {
    local label="$1"
    local expected_participant="$2"
    local expected_host="$3"
    local expected_token="$4"
    local xcconfig="$DERIVED_ROOT/$label.xcconfig"
    local log="$DERIVED_ROOT/$label-build.log"

    if [[ "$label" == "configured" ]]; then
        {
            printf 'LOOKALS_BSD_TOUR_PARTICIPANT_ID = %s\n' "$expected_participant"
            printf 'LOOKALS_BSD_TOUR_WEBSOCKET_HOST = %s\n' "$expected_host"
            printf 'LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN = %s\n' "$expected_token"
        } > "$xcconfig"
    else
        : > "$xcconfig"
    fi

    xcodebuild \
        -project "$ROOT_DIR/Lookals.xcodeproj" \
        -scheme Lookals \
        -sdk iphonesimulator \
        -configuration Debug \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "$DERIVED_ROOT/$label-derived" \
        -xcconfig "$xcconfig" \
        build CODE_SIGNING_ALLOWED=NO > "$log" 2>&1

    local plist="$DERIVED_ROOT/$label-derived/Build/Products/Debug-iphonesimulator/Lookals.app/Info.plist"
    [[ -f "$plist" ]]
    [[ "$(plutil -extract LOOKALS_BSD_TOUR_PARTICIPANT_ID raw "$plist")" == "$expected_participant" ]]
    [[ "$(plutil -extract LOOKALS_BSD_TOUR_WEBSOCKET_HOST raw "$plist")" == "$expected_host" ]]
    [[ "$(plutil -extract LOOKALS_BSD_TOUR_DEMO_JOIN_TOKEN raw "$plist")" == "$expected_token" ]]
}

build_and_check configured gisella configured.example.test non-secret-test-sentinel
build_and_check unconfigured '' '' ''

echo "BSD Tour configured and unconfigured Info.plist keys verified (token value redacted)."
