#!/bin/bash

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
# compgen shellinq

_shellinq_comp(){
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W  "$(cat $selfPath/../doc/methods.txt|sed 's/\n//g')" -- $cur) )
}
complete  -F _shellinq_comp shellinq
