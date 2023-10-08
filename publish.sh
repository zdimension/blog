#!/usr/bin/env bash

# usage: ./publish.sh write-up-on-a-fun-jigsaw-puzzle-problem
# will rename _drafts/write-up-on-a-fun-jigsaw-puzzle-problem.md to _posts/YYYY-MM-DD-write-up-on-a-fun-jigsaw-puzzle-problem.md
# and move rename assets/posts/write-up-on-a-fun-jigsaw-puzzle-problem to assets/posts/YYYY-MM-DD-write-up-on-a-fun-jigsaw-puzzle-problem

POST=$1

# check empty first
if [ -z "$POST" ]; then
    echo "Usage: ./publish.sh name_or_path"
    exit 1
fi

# if ends with .md, remove it
if [[ $POST == *.md ]]; then
    POST=${POST%.md}
fi

POSTPATH=$POST

# if doesn't exist, try prepend _drafts/
if [ ! -f $POSTPATH.md ]; then
    POSTPATH=_drafts/$POSTPATH
fi

# check exists
if [ ! -f $POSTPATH.md ]; then
    echo "File $POST.md or $POSTPATH.md does not exist"
    exit 1
fi

BASENAME=$(basename $POSTPATH)

NEW_NAME=$(date +%Y-%m-%d)-$BASENAME

mv $POSTPATH.md _posts/$NEW_NAME.md
mv assets/posts/$BASENAME assets/posts/$NEW_NAME

./rebuild.sh