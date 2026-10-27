#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p bin
em++ strings.cpp -I ../../../include -O2 --bind "$@" -o bin/strings.js
node bin/strings.js > bin/strings-actual.txt
diff -u strings-stdout.txt bin/strings-actual.txt