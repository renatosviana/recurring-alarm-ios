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
require "$project" 'ENABLE_TESTABILITY = YES' 'app Debug configuration enables testability'
require "$project" 'PRODUCT_MODULE_NAME = T01PrototypeApp' 'app module name is explicit'
require "$project" 'TEST_HOST = "$(BUILT_PRODUCTS_DIR)/T01PrototypeApp.app/T01PrototypeApp"' 'test host points to the app executable'
require "$project" 'dependencies = (A90000000000000000000002)' 'test target depends on the app target'
require "$project" 'remoteGlobalIDString = A50000000000000000000001' 'test dependency points to the app target'
require "$scheme" '<Testables>' 'shared scheme has a Testables container'
require "$scheme" 'BlueprintIdentifier = "A50000000000000000000002"' 'shared scheme references the test target'
require "$scheme" 'BuildableName = "T01PrototypeAppTests.xctest"' 'shared scheme references the test product'
require "$scheme" 'buildForTesting = "YES"' 'shared scheme builds the test target for testing'

echo "PASS: shared XCTest scheme and project references are present"
