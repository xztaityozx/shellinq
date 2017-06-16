#!/bin/bash


#dir path

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
# 型リスト
if [[ "$1" =~ ^\[.*\]$ ]]; then
  types="$1"
  shift
else
  types="[int]"
fi

types=`echo $types|sed -E 's/(\[|\])//g'`
typecnt=`echo $types|sed -E 's/([a-z]|[A-Z]|[0-9])//g'|wc -m`


getScript_single_no_string="
  var list=new List<$types>();
  string s;
  while((s=Console.ReadLine())!=null){
    list.Add($types.Parse(s));
  }
"
getScript_string="
  var list=new List<string>();
  string s;
  while((s=Console.ReadLine())!=null){
    list.Add(s);
  }
"

typeBox=$(echo "$types"|sed 's/,/\n/g'|awk '
  BEGIN{
    idx=0
  }
  {
    if($1=="string"){
      printf "items[%d],",idx
    }else{
      printf "%s.Parse(items[%d]),",$1,idx
    }
    idx++
  }
'|sed 's/,$//g')

#echo $typeBox

getScript_tuple="
  var list=new List<Tuple<$types>>();
  string s;
  while((s=Console.ReadLine())!=null){
    var items=s.Split(' ').ToArray();
    var tuple=new Tuple<$types>($typeBox);
    list.Add(tuple);
  }
"
outScript_single="Console.WriteLine(item);"

outScript_tuple="Console.WriteLine("$(seq 1 $typecnt|awk '
  {
    printf "item.Item%d+\" \"+",$1
  }
'|sed 's/\+$//g')");"
if [ $typecnt -ne 1 ]; then
  outScript_foreach="
    foreach(var item in linqed){
      $outScript_tuple
    }
  "
elif [ $types = "string" ]; then
  outScript_foreach="
    foreach(var item in linqed){
      $outScript_single
    }
  "
else
  outScript_foreach="
    foreach(var item in linqed){
      $outScript_single
    }
  "
fi

#echo $getScript_tuple

#make Query
dockedQuery="var linqed=list"

while [ $# -gt 0 ] ; do
  func="$1"
  shift
  query="$1"
  shift

  #$1,$2,...,.$X -> list[i].Item1,.Item2,...,.ItemX
  #ex) Select $1 -> Select _=>_.Item1
  if [[ $query =~ '$' ]]; then
    if [ $typecnt -eq 1 ]; then
      query="$(echo $query|sed -E 's/\$[0-9]+/_=>_/g')"
    else
      query="_=>"$(echo $query|sed 's/\$/_.Item/g')
    fi
  fi
  
  if [ "$query" = "" ] || [ "$(grep $query $selfPath/../doc/methods.txt )" != "" ]; then
    echo -e "\e[1;31mInvalid Query. @$func($query)\e[0;39m"
    exit 1
  fi
  
  #Convert ex) select -> Select
  func=$(echo $func|sed 's|\(.*\)|\L\1|')
  func_greped=$(grep -w "$func" $selfPath/../doc/methods.txt|awk '{print $2}')
  if [ "$func_greped" = "" ]; then
    echo "$func is not Linq method or not supported."
    exit 1
  else
    func=$func_greped
  fi
  dockedQuery=$dockedQuery".$func($query)"
done
dockedQuery=$dockedQuery";"


#generate script
script=""
if [ $types = "string" ]; then
  script="$getScript_string"
elif [ $typecnt -eq 1 ]; then
  script="$getScript_single_no_string"
else
  script="$getScript_tuple"
fi

script="$script $dockedQuery $outScript_foreach"
#echo $script
csharp -e "$script"

