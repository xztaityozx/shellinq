
using System;
using System.Collections.Generic;
using System.Linq;

class Program{
  static void Main(){
    new Calc().Solve();
  }

class InnerValueClass{
  public string Item1;
public int Item2;
public string Item3;
public string Item4;
public string Item5;
public string Item6;
public string Item7;
public string Item8;
public string Item9;
  public InnerValueClass(
  string item1,int item2,string item3,string item4,string item5,string item6,string item7,string item8,string item9
){
  Item1 = item1;
Item2 = item2;
Item3 = item3;
Item4 = item4;
Item5 = item5;
Item6 = item6;
Item7 = item7;
Item8 = item8;
Item9 = item9;
}
  
public override string ToString(){
  return Item1+" "+Item2+" "+Item3+" "+Item4+" "+Item5+" "+Item6+" "+Item7+" "+Item8+" "+Item9+" ";
}

}


  class Calc{
    public void Solve(){
 
  var list=new List<InnerValueClass>();
  string s;
  while((s=Console.ReadLine())!=null){
    var items=s.Split(' ').ToArray();
    var tuple=new InnerValueClass(items[0],int.Parse(items[1]),items[2],items[3],items[4],items[5],items[6],items[7],items[8]);
    list.Add(tuple);
  }
 var linqed=list.Select(_=>new Tuple<string,string>(_.Item9,_.Item3)); linqed.WL(); 
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

