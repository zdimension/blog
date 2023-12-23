#!/bin/sh

echo "Removing EXIF metadata"

if ! which exiv2 > /dev/null; then
    echo "Please install the exiv2 tool"
    exit 0
fi

find assets/posts \( -iname '*.png' -or -iname '*.jpg' -or -iname '*.jpeg' \) -print0 | xargs -0 exiv2 -d a
