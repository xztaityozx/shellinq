
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
 var linqed=list.Select(_=>_%2==0); linqed.WL(); 
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

