
class XpathSequence {
  
  List<XpathItem> items = new List<XpathItem>();

  XpathSequence GetAtomicValues(){
    XpathSequence result = new XpathSequence();
    for(XpathItem item in this.items){
      if(!item.isNode())result.items.add(item);
    }
    return result;
  } 

  XpathSequence getNodesOfType(XpathNodeType nodeType){
    XpathSequence result = new XpathSequence();
    for(XpathItem item in this.items){
      if(item.isNode() && item.nodeType==nodeType) {
        result.items.add(item);
      }
    }
    return result;   
  } 
  
  void sortItemsByDocOrder(){
    //TODO:
  }
  
  //for debug output
  String toString(){
    String result = "";
    for(XpathItem item in this.items){
      if(item.isNode()){
        result = result.concat("<${item.toString()}> , ");  
      }
      else {
        result = result.concat("${item.toString()} , ");
      }
    } 
    return result == ""?"nothing":result.substring(0,result.lastIndexOf(','));
  }
  
  //for debug output  
  String toHTMLString(){
    String result = "";
    for(XpathItem item in this.items){
      if(item.isNode()){
        var s = item.toString();
        if(s.contains("\"")){
          result = result.concat("$s , ");
        }
        else {
          result = result.concat("&lt;$s&gt; , ");
        }
      }
      else {
        result = result.concat("${item.toString()} , ");
      }
    } 
    return result == ""?"nothing":result.substring(0,result.lastIndexOf(','));
  }  
  
}
