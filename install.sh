#!/bin/bash

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

sudo apt install mono-mcs

echo "## shellinq" >> ~/.bashrc
echo "alias shellinq='$selfPath/sh/shellinq.sh'" >> ~/.bashrc
echo ". $selfPath/sh/_shellinq_comp.sh" >> ~/.bashrc
