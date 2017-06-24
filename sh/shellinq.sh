#!/bin/bash


#dir path

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

$selfPath/cslinq.sh "$@"
