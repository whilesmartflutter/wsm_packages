#!/usr/bin/env bash
# Tag and push a release for one package in this workspace.
# Usage: ./scripts/release.sh <package> <version>
# Example: ./scripts/release.sh wsm_core 0.1.0
set -euo pipefail

PACKAGE="${1:?usage: release.sh <package> <version>}"
VERSION="${2:?usage: release.sh <package> <version>}"
PUBSPEC="packages/$PACKAGE/pubspec.yaml"
TAG="$PACKAGE-v$VERSION"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "error: $PUBSPEC not found" >&2
  exit 1
fi

DECLARED=$(grep -E '^version:' "$PUBSPEC" | awk '{print $2}')
if [[ "$DECLARED" != "$VERSION" ]]; then
  echo "error: $PUBSPEC declares version $DECLARED, expected $VERSION" >&2
  exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "error: tag $TAG already exists" >&2
  exit 1
fi

git tag -a "$TAG" -m "$PACKAGE $VERSION"
git push origin "$TAG"
echo "released $TAG"
