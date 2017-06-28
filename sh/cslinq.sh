#!/bin/bash


#dir path

selfPath="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
tmpPath="$selfPath/../tmp/tmp.txt"
echo  > $tmpPath
sed '/^$/d' -i $tmpPath


read firstLINE
firstLINE=$(echo $firstLINE|sed -E 's/ +/ /g')
expectTypecnt=$(echo $firstLINE|sed -E 's/( |\t)/\n/g'|sed '/^$/d'|wc -l)

# 型リスト
if [[ "$1" =~ ^\[.*\]$ ]]; then
  types="$1"
  shift
else
  types="["$(echo $firstLINE|sed 's/ /\n/g'|while read LINE;do
    expr $LINE + 1 > /dev/null 2>&1
    if [ $? -lt 2 ];then echo -n "int,";continue;fi
    echo "$LINE"|grep "\."|grep -v "^\."|grep -v "\-\." > /dev/null 2>&1
    if [ $? -eq 0 ];then res=$(echo "$LINE + 1"|bc 2>&1);
      if [[ "$res" =~ "error" ]];then echo -n "string,";
      else echo -n "double,"
      fi
    else
      echo -n "string,"
    fi
  done|sed 's/,$//g'
  )"]"
fi

types=`echo $types|sed -E 's/(\[|\])//g'`
typecnt=`echo $types|sed -E 's/([a-z]|[A-Z]|[0-9])//g'|wc -m`

#echo $types

#exit 0

innerValueClass_members=$(echo "$types"|sed 's/,/\n/g'|awk 'BEGIN{
  idx=1
}{
  print "public "$1" Item"idx";"
  idx++
}')
innerValueClass_Constructer="public InnerValueClass(
  $(echo $types|sed 's/,/\n/g'|awk '
    BEGIN{idx=1}
    {
      printf "%s item%d,",$1,idx
      idx++
    }
  '|sed 's/,$//g')
){
  $(echo $types|sed 's/,/\n/g'|awk 'BEGIN{idx=1}{
    print "Item"idx" = item"idx";"
    idx++
  }
  ')
}"
innerValueClass_ToString="
public override string ToString(){
  return $(echo $types|sed 's/,/\n/g'|awk 'BEGIN{idx=1}{
    printf "Item%d+\" \"+",idx
    idx++
  }'|sed 's/+$//g');
}
"

innerValueClass="
class InnerValueClass{
  $innerValueClass_members
  $innerValueClass_Constructer
  $innerValueClass_ToString
}
"



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
  var list=new List<InnerValueClass>();
  string s;
  while((s=Console.ReadLine())!=null){
    var items=s.Split(' ').ToArray();
    var tuple=new InnerValueClass($typeBox);
    list.Add(tuple);
  }
"
outScript_foreach="linqed.ToList().ForEach(Console.WriteLine);"

#echo $getScript_tuple

#make Query
dockedQuery="var linqed=list"

outputFormat_flag=0

while [ $# -gt 0 ] ; do
  func="$1"
  shift
  query="$1"
  shift

  # remove \n
  query=$(echo $query|sed 's/\n//g')

  # -o option
  if [ "$func" = "-o" ]; then
    outputFormat_flag=1
    if [[ $query =~ '$0' ]];then
      query=$(echo $query|sed 's/$0/item.ToString()/g')
    fi
    if [[ $query =~ '$' ]]; then
      if [ $typecnt -eq 1 ]; then
        query=$(echo $query|sed 's/$1/item/g')
      else
        query=$(echo $query|sed 's/\$/item.Item/g')
      fi
    fi
    outScript_foreach="foreach(var item in linqed){$query}"
    continue
  fi

  #$1,$2,...,.$X -> list[i].Item1,.Item2,...,.ItemX
  #ex) Select $1 -> Select _=>_.Item1
  if [[ $query =~ '$' ]]; then
    if [ "$query" = '$0' ]; then
      query="_=>_.ToString()"
    elif [ $typecnt -eq 1 ]; then
      query="$(echo "_=>"$query|sed 's/$0/_.ToString()/g'|sed -E 's/\$[1-9]+/_/g')"
    else
      query="_=>"$(echo $query|sed 's/$0/_.ToString()/g'|sed 's/\$/_.Item/g')
    fi
  fi
  
  grquery=$(echo $query|sed s'/ //g')

  if [ "$(grep $grquery $selfPath/../doc/methods.txt )" != "" ]; then
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
  #echo $dockedQuery
done

if [ $outputFormat_flag -eq 1 ]; then
  dockedQuery=$dockedQuery";"
else
  dockedQuery=$dockedQuery";"
fi


#generate script
script=""
if [ "$types" = "string" ]; then
  script="$getScript_string"
elif [ $typecnt -eq 1 ]; then
  script="$getScript_single_no_string"
else
  script="$getScript_tuple"
fi

script="$script $dockedQuery $outScript_foreach"
#echo $script
#if [ $typecnt -gt 1 ]; then
#  csharp -e "$script"|sed -E 's/(^\(|\)$)//g;s/, / /g'
#else
#  csharp -e "$script"
#fi


cs_header="
using System;
using System.Collections.Generic;
using System.Linq;

class Program{
  static void Main(){
    new Calc().Solve();
  }
$innerValueClass

  class Calc{
    public void Solve(){
"
cs_bottom="
    }
  }
}
"

echo "$cs_header $script $cs_bottom" > $selfPath/script.cs

mcs $selfPath/script.cs 1>/dev/null 2>/dev/null 

#rm $selfPath/script.cs

if [ $? != 0 ]; then
  exit 1
fi


if [ $typecnt -gt 1 ]; then
  echo $firstLINE|mono $selfPath/script.exe
  sed -E 's/ +/ /g' | mono $selfPath/script.exe|sed -E 's/(^\(|\)$)//g;s/, / /g'
else
  echo $firstLINE|mono $selfPath/script.exe
  sed -E 's/ +/ /g' | mono $selfPath/script.exe
fi

#rm $selfPath/script.exe
