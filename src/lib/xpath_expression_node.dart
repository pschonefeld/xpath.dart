part of xpath.dart;

class XpathExpressionNode {
  bool isExprStart = false;
  bool isRoot = false;
  List<XpathExpressionNode> children = [];
  List<XpathExpressionNode> siblings = [];  
  XpathSyntaxNodeKind kind = new XpathSyntaxNodeKind.set(XpathSyntaxNodeKind.UNDEFINED);
  XpathToken token;

  XpathExpressionNode();  
  
  XpathExpressionNode.root(){
    this.isRoot = true;    
  }
  
  XpathTokenName getAxisName(){
    var result;
    if(this.kind == XpathSyntaxNodeKind.ETNK_FORWARD_AXIS || 
       this.kind == XpathSyntaxNodeKind.ETNK_REVERSE_AXIS) {
      result = this.token.item.context.name;
    }
    else return null; 
  }
  
  void traverse(){}  //TODO:  candidate remove
  
  void visit(){
    switch(this.kind.value){
      case XpathSyntaxNodeKind.ETNK_STEP: 
        if(this.isExprStart==false){
          ; //TODO:
        }
        break;
    }
  }

  String testTraverse(){
    String result = "";
    testVisit();
 
    for(XpathExpressionNode node in this.siblings){
      result += " sibling: ${node.testTraverse()}";
    }
    
    for(XpathExpressionNode node in this.children){
      result += " child: ${node.testTraverse()}";
    }
    
    return "$result\n";
  }
  
  String testVisit(){
    return " Kind: $kind";
  }
  
  
}
