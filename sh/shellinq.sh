#!/bin/bash


#dir path

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

if [ $1 = "-c#" ]; then
  shift
  $selfPath/cslinq.sh "$@"
  exit 0
fi

commandQuery=""

while $# -gt 0 ; do
  $func="$1"
  shift
  $query="$1"
  shift

  
done
