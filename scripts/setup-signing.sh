#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
LOCAL_CONFIG="$ROOT_DIR/Config/Signing.local.xcconfig"
SHARED_CONFIG="$ROOT_DIR/Config/Signing.xcconfig"
PROJECT_FILE="$ROOT_DIR/Lookals.xcodeproj/project.pbxproj"

TEAM_ID="${LOOKALS_DEVELOPMENT_TEAM:-}"
BUNDLE_ID="${LOOKALS_BUNDLE_IDENTIFIER:-}"
CODE_SIGN_ENTITLEMENTS="${LOOKALS_CODE_SIGN_ENTITLEMENTS:-}"
SWIFT_ACTIVE_COMPILATION_CONDITIONS="${LOOKALS_SWIFT_ACTIVE_COMPILATION_CONDITIONS:-}"
SOURCE_PROJECT=""
INSTALL_HOOKS=1
NON_INTERACTIVE=0

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/setup-signing.sh [TEAM_ID] [BUNDLE_ID]
  ./scripts/setup-signing.sh --team TEAM_ID --bundle-id BUNDLE_ID
  ./scripts/setup-signing.sh --from-project /path/to/WorkingApp.xcodeproj

Options:
  --from-project PATH     Read signing values from an existing working .xcodeproj.
  --team TEAM_ID          Apple Developer Team ID, for example ABCDE12345.
  --bundle-id BUNDLE_ID   Bundle identifier to use locally.
  --no-hooks              Do not configure this repo to use .githooks.
  --non-interactive       Fail instead of prompting for missing values.
  -h, --help              Show this help.

Environment:
  LOOKALS_DEVELOPMENT_TEAM and LOOKALS_BUNDLE_IDENTIFIER can also be used.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --from-project)
      if [ "$#" -lt 2 ]; then
        echo "--from-project requires a value." >&2
        usage >&2
        exit 2
      fi
      SOURCE_PROJECT="${2:-}"
      shift 2
      ;;
    --team)
      if [ "$#" -lt 2 ]; then
        echo "--team requires a value." >&2
        usage >&2
        exit 2
      fi
      TEAM_ID="${2:-}"
      shift 2
      ;;
    --bundle-id)
      if [ "$#" -lt 2 ]; then
        echo "--bundle-id requires a value." >&2
        usage >&2
        exit 2
      fi
      BUNDLE_ID="${2:-}"
      shift 2
      ;;
    --no-hooks)
      INSTALL_HOOKS=0
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -z "$TEAM_ID" ]; then
        TEAM_ID="$1"
      elif [ -z "$BUNDLE_ID" ]; then
        BUNDLE_ID="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

project_pbxproj_path() {
  local path="$1"

  case "$path" in
    *.pbxproj)
      printf '%s\n' "$path"
      ;;
    *.xcodeproj)
      printf '%s\n' "$path/project.pbxproj"
      ;;
    *)
      if [ -f "$path/project.pbxproj" ]; then
        printf '%s\n' "$path/project.pbxproj"
      else
        printf '%s\n' "$path"
      fi
      ;;
  esac
}

read_project_setting() {
  local file="$1"
  local key="$2"

  [ -f "$file" ] || return 0
  awk -v key="$key" '
    {
      line = $0
      assignment = index(line, " = ")
      if (assignment == 0) {
        next
      }
      setting = substr(line, 1, assignment - 1)
      value = substr(line, assignment + 3)
      if (setting ~ "^[ \t\"]*" key "([[][^]]+[]])?[ \t\"]*$") {
        gsub(/[\"; \t\r]/, "", value)
        if (value != "" && value !~ /\$\(/) {
          print value
          exit
        }
      }
    }
  ' "$file"
}

read_exact_project_setting() {
  local file="$1"
  local key="$2"

  [ -f "$file" ] || return 0
  awk -v key="$key" '
    {
      line = $0
      assignment = index(line, " = ")
      if (assignment == 0) {
        next
      }
      setting = substr(line, 1, assignment - 1)
      value = substr(line, assignment + 3)
      if (setting ~ "^[ \t\"]*" key "[ \t\"]*$") {
        gsub(/[\"; \t\r]/, "", value)
        if (value != "" && value !~ /\$\(/) {
          print value
          exit
        }
      }
    }
  ' "$file"
}

read_project_bundle_id() {
  local file="$1"
  local value

  value="$(read_exact_project_setting "$file" PRODUCT_BUNDLE_IDENTIFIER)"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
    return
  fi

  read_project_setting "$file" PRODUCT_BUNDLE_IDENTIFIER
}

read_config_value() {
  local file="$1"
  local key="$2"

  [ -f "$file" ] || return 0
  awk -F= -v key="$key" '
    $1 ~ "^[ \t]*" key "[ \t]*$" {
      value = $2
      gsub(/[\"; \t\r]/, "", value)
      if (value != "" && value !~ /\$\(/) {
        print value
      }
    }
  ' "$file" | tail -n 1
}

detect_project_team() {
  [ -f "$PROJECT_FILE" ] || return 0
  read_project_setting "$PROJECT_FILE" DEVELOPMENT_TEAM
}

detect_certificate_team() {
  command -v security >/dev/null 2>&1 || return 0

  local teams
  local count
  teams="$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null \
      | sed -nE 's/.*Apple Development:.*\(([A-Z0-9]{10})\).*/\1/p' \
      | sort -u
  )"
  count="$(printf '%s\n' "$teams" | sed '/^$/d' | wc -l | tr -d ' ')"

  if [ "$count" = "1" ]; then
    printf '%s\n' "$teams"
  fi
}

prompt_value() {
  local label="$1"
  local current="$2"
  local value

  if [ "$NON_INTERACTIVE" = "1" ]; then
    printf '%s\n' "$current"
    return
  fi

  if [ -n "$current" ]; then
    printf '%s [%s]: ' "$label" "$current" >&2
  else
    printf '%s: ' "$label" >&2
  fi

  IFS= read -r value
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$current"
  fi
}

if [ -n "$SOURCE_PROJECT" ]; then
  SOURCE_PROJECT_FILE="$(project_pbxproj_path "$SOURCE_PROJECT")"
  if [ ! -f "$SOURCE_PROJECT_FILE" ]; then
    echo "Could not find project file: $SOURCE_PROJECT_FILE" >&2
    exit 1
  fi

  if [ -z "$TEAM_ID" ]; then
    TEAM_ID="$(read_project_setting "$SOURCE_PROJECT_FILE" DEVELOPMENT_TEAM)"
  fi

  if [ -z "$BUNDLE_ID" ]; then
    BUNDLE_ID="$(read_project_bundle_id "$SOURCE_PROJECT_FILE")"
  fi
fi

if [ -z "$TEAM_ID" ]; then
  TEAM_ID="$(read_config_value "$LOCAL_CONFIG" LOOKALS_DEVELOPMENT_TEAM)"
fi

if [ -z "$TEAM_ID" ]; then
  TEAM_ID="$(detect_project_team)"
fi

if [ -z "$TEAM_ID" ]; then
  TEAM_ID="$(detect_certificate_team)"
fi

if [ -z "$BUNDLE_ID" ]; then
  BUNDLE_ID="$(read_config_value "$LOCAL_CONFIG" LOOKALS_BUNDLE_IDENTIFIER)"
fi

if [ -z "$BUNDLE_ID" ]; then
  BUNDLE_ID="$(read_config_value "$SHARED_CONFIG" LOOKALS_BUNDLE_IDENTIFIER)"
fi

if [ -z "$CODE_SIGN_ENTITLEMENTS" ]; then
  CODE_SIGN_ENTITLEMENTS="$(read_config_value "$LOCAL_CONFIG" LOOKALS_CODE_SIGN_ENTITLEMENTS)"
fi

if [ -z "$SWIFT_ACTIVE_COMPILATION_CONDITIONS" ]; then
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="$(read_config_value "$LOCAL_CONFIG" LOOKALS_SWIFT_ACTIVE_COMPILATION_CONDITIONS)"
fi

TEAM_ID="$(prompt_value "Apple Developer Team ID" "$TEAM_ID")"
BUNDLE_ID="$(prompt_value "Local bundle identifier" "$BUNDLE_ID")"

if ! [[ "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Team ID must be 10 uppercase letters or digits." >&2
  exit 1
fi

if [ -z "$BUNDLE_ID" ]; then
  echo "Bundle identifier cannot be empty." >&2
  exit 1
fi

mkdir -p "$(dirname "$LOCAL_CONFIG")"
cat > "$LOCAL_CONFIG" <<EOF
// Local signing overrides. This file is ignored by git.
// Generated by scripts/setup-signing.sh.

LOOKALS_DEVELOPMENT_TEAM = $TEAM_ID
LOOKALS_BUNDLE_IDENTIFIER = $BUNDLE_ID
EOF

if [ -n "$CODE_SIGN_ENTITLEMENTS" ]; then
  echo "LOOKALS_CODE_SIGN_ENTITLEMENTS = $CODE_SIGN_ENTITLEMENTS" >> "$LOCAL_CONFIG"
fi

if [ -n "$SWIFT_ACTIVE_COMPILATION_CONDITIONS" ]; then
  echo "LOOKALS_SWIFT_ACTIVE_COMPILATION_CONDITIONS = $SWIFT_ACTIVE_COMPILATION_CONDITIONS" >> "$LOCAL_CONFIG"
fi

if [ "$INSTALL_HOOKS" = "1" ] && command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" config core.hooksPath .githooks 2>/dev/null; then
    echo "Configured git hooks from .githooks."
  else
    echo "Could not configure git hooks automatically. Run this once if you want the pre-commit guard:" >&2
    echo "  git config core.hooksPath .githooks" >&2
  fi
fi

echo "Wrote ${LOCAL_CONFIG#$ROOT_DIR/}."
echo "Xcode will use team $TEAM_ID and bundle id $BUNDLE_ID for this checkout."
