part of xpath_dart;

///is the input and output type of the expression
class Sequence {

  List<Item> items = new List<Item>();

  void add(Item item){
    this.items.add(item);
  }

  Sequence GetAtomicValues(){
    Sequence result = new Sequence();
    items.where((x) => !x.isNode())
         .forEach((x) => result.add(x));
    return result;
  }

  Sequence getNodesOfType(NodeType nodeType) {
    Sequence result = new Sequence();
    items.where((x) => !x.isNode() && x.nodeType == nodeType)
         .forEach((x) => result.add(x));
    return result;
  }

  void sortItemsByDocOrder(){
    //TODO:
  }

  //for debug output
  @override
  String toString(){
    String result = '';
    this.items.forEach((i){
      if(i.isNode()) result += '<${i.toString()}> , ';
      else result+= '${i.toString()} , ';
    });
    return result == ''?'nothing':result.substring(0,result.lastIndexOf(','));
  }

}