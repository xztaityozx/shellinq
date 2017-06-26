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



innerValueClass_members=$(echo $types|sed 's/,/\n/g'|awk 'BEGIN{
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
outScript_foreach="linqed.WL();"

#echo $getScript_tuple

#make Query
dockedQuery="var linqed=list"

while [ $# -gt 0 ] ; do
  func="$1"
  shift
  query="$1"
  shift

  # remove \n
  query=$(echo $query|sed 's/\n//g')

  # -o option
  if [ "$func" = "-o" ]; then
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
    if [ $typecnt -eq 1 ]; then
      query="$(echo "_=>"$query|sed -E 's/\$[0-9]+/_/g')"
    else
      query="_=>"$(echo $query|sed 's/\$/_.Item/g')
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
public static class Utils{
  public static void WL(this object obj) {
		Console.WriteLine(obj);
	}
	public static void WL<T>(this IEnumerable<T> list) {
		foreach (var item in list) {
			item.WL();
	  }
  }
}
"

echo "$cs_header $script $cs_bottom" > $selfPath/script.cs

mcs $selfPath/script.cs 

if [ $typecnt -gt 1 ]; then
  mono $selfPath/script.exe|sed -E 's/(^\(|\)$)//g;s/, / /g'
else
  mono $selfPath/script.exe
fi
