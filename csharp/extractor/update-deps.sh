#! /usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

(
    cd "$SCRIPT_DIR" || exit 1
    DEP_DIR="$(pwd)"
    (dotnet tool restore && dotnet paket install)
    cd ../../..
    ./build --bazel run @rules_dotnet//tools/paket2bazel:paket2bazel.exe -- --dependencies-file "$DEP_DIR"/paket.dependencies --output-folder "$DEP_DIR"
)
