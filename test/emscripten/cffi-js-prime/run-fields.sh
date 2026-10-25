#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p bin
em++ fields.cpp -I ../../../include -O2 --bind "$@" -o bin/fields.js
node bin/fields.js > bin/fields-actual.txt
diff -u fields-stdout.txt bin/fields-actual.txt