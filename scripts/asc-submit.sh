#!/bin/sh
# Submit the build the export step just uploaded. ExportOptions.plist has
# destination=upload, so there is never a local IPA for `asc publish appstore` to find.
# Usage: scripts/asc-submit.sh <app-id> <version> [IOS|MAC_OS]
set -eu
APP=$1 VERSION=$2 PLATFORM=${3:-IOS}
BUILD_NUMBER=$(grep -m1 CURRENT_PROJECT_VERSION ios/Grapher.xcodeproj/project.pbxproj | tr -dc 0-9)

asc versions create --app "$APP" --platform "$PLATFORM" --version "$VERSION" --output json >/dev/null 2>&1 || true

i=0
while [ $i -lt 40 ]; do
  BUILD=$(asc builds list --app "$APP" --limit 10 --output json 2>/dev/null | head -1 | python3 -c "
import sys, json
print(next((b['id'] for b in json.load(sys.stdin)['data']
  if b['attributes']['version'] == '$BUILD_NUMBER' and b['attributes']['processingState'] == 'VALID'), ''))")
  [ -n "$BUILD" ] && break
  i=$((i + 1)); sleep 30
done
[ -n "$BUILD" ] || { echo "build $BUILD_NUMBER never became VALID" >&2; exit 1; }

asc review submit --app "$APP" --platform "$PLATFORM" --version "$VERSION" --build-id "$BUILD" --confirm --output json
