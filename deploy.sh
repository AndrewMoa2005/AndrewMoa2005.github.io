#!/bin/bash

echo -e " Deploying updates to GitHub... "

rm -rf public
# rm -rf docs

cd docs
find * | grep -v CNAME | xargs rm -rf
cd ..

# hugo build
hugo build -d docs

git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push -u origin main

