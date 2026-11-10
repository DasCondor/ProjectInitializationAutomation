#!/bin/bash

function create() {

    source .env
    remote=$(python create.py "$1") || return 1
    cd "$FILEPATH$1"
    git init
    git remote add origin "$remote"
    touch README.md
    git add .
    git commit -m "Initial commit"
    git push -u origin HEAD
    code .
}
