
using System;
using System.Collections.Generic;
using System.Linq;

class Program{
  static void Main(){
    new Calc().Solve();
  }

class InnerValueClass{
  public int Item1;
  public InnerValueClass(
  int item1
){
  Item1 = item1;
}
  
public override string ToString(){
  return Item1+" ";
}

}


  class Calc{
    public void Solve(){
 
  var list=new List<int>();
  string s;
  while((s=Console.ReadLine())!=null){
    list.Add(int.Parse(s));
  }
 var linqed=list.Select(x=>{return x%15==0?"FizzBuzz":x%5==0?"Buzz":x%3==0?"Fizz":""+x;}).Select(_=>{Console.WriteLine(_.ToString()); return 0;});  
    }
  }
}

