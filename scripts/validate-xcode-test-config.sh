#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="$root/T01Prototype/T01PrototypeApp.xcodeproj/project.pbxproj"
scheme="$root/T01Prototype/T01PrototypeApp.xcodeproj/xcshareddata/xcschemes/T01PrototypeApp.xcscheme"

require() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq -- "$pattern" "$file"; then
    echo "FAIL: $description" >&2
    exit 1
  fi
}

require "$project" 'A50000000000000000000002 /* T01PrototypeAppTests */' 'test target exists in the project'
require "$project" 'productType = "com.apple.product-type.bundle.unit-test"' 'test target is an XCTest bundle'
require "$project" 'A20000000000000000000005 /* AlarmStoreTests.swift */' 'test source is referenced by the project'
require "$scheme" '<Testables>' 'shared scheme has a Testables container'
require "$scheme" 'BlueprintIdentifier = "A50000000000000000000002"' 'shared scheme references the test target'
require "$scheme" 'BuildableName = "T01PrototypeAppTests.xctest"' 'shared scheme references the test product'

echo "PASS: shared XCTest scheme and project references are present"
