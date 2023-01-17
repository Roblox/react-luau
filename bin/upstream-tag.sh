#!/bin/bash

REACT_PATH=$1
EQUIVALENT_FOLDER=$2

echo "Matching upstream files $REACT_PATH/$EQUIVALENT_FOLDER..."

if [ $# -ne 2 ]; then
  echo "Usage:
upstream-tag.sh <path_to_react> <target_folder>

path_to_react:
    The path to the local copy of the react repository; this is where we find
    the upstream version information (using 'git log' commands)

target_folder:
    For example, if you run this script from the 'modules' folder, then
    target_folder should be 'packages'. If you run it from 'modules/react-is/src,
    then target_folder should be 'packages/react-is/src'"
  exit 1
fi

count=0
for file in $(find * -name "*.lua")
do
  if [[ "$file" == *"roblox-jest"* ]] || [[ "$file" == *"roblox-js-polyfill"* ]]; then
    echo "SKIP: $file is Roblox-only"
    continue
  fi

  if [[ "$file" == *".roblox."*"lua" ]]; then
    echo "SKIP: $file is Roblox-only"
    continue
  fi

  if [[ `head -n 1 $file` == "-- ROBLOX upstream:"* ]]; then
    echo "SKIP: $file already has 'upstream' comment"
    continue
  fi

  targetFileName="${file/-internal.spec/-test.internal}"
  targetFileName="${targetFileName/.spec/-test}"
  targetFileName="${targetFileName/.lua/.js}"
  targetFile="$EQUIVALENT_FOLDER/$targetFileName"

  if [[ ! -f "$REACT_PATH/$targetFile" ]]; then
    echo "SKIP: Equivalent file $targetFileName not found"
    continue
  fi

  pushd $REACT_PATH > /dev/null
  COMMIT=`git log -- $targetFile | head -n 1 | sed "s/commit //g"`
  REPO_PATH=`realpath --relative-to=$REACT_PATH $targetFile`
  PREFIX="-- ROBLOX upstream: https://github.com/facebook/react/blob/$COMMIT/$REPO_PATH"
  if [[ "$COMMIT" == "" ]]; then
    echo "SKIP: Could not find commit for $targetFile -> $file"
    continue
  fi

  count=$((count+1))

  echo ""
  echo "Prepend to $file..."
  echo $PREFIX
  popd > /dev/null
  echo "$PREFIX
$(cat $file)" > $file
done

echo -e "\nAdded upstream tag to $count files"