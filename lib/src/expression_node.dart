part of xpath_dart;

class ExpressionNode {
  bool isExprStart = false;
  bool isRoot = false;
  List<ExpressionNode> children = [];
  List<ExpressionNode> siblings = [];
  SyntaxNodeKind kind = SyntaxNodeKind.UNDEFINED;
  Token token;

  ExpressionNode();
  
  ExpressionNode.root(){
    this.isRoot = true;    
  }
  
  TokenName getAxisName(){
    var result;
    if(this.kind == SyntaxNodeKind.ETNK_FORWARD_AXIS ||
       this.kind == SyntaxNodeKind.ETNK_REVERSE_AXIS) {
      result = this.token.item.context.name;
    }
    else return null;
    return result;
  }
  
  void traverse(){}  //TODO:  candidate remove
  
  void visit(){
    switch(this.kind){
      case SyntaxNodeKind.ETNK_STEP:
        if(this.isExprStart==false){
          ; //TODO:
        }
        break;
      default: break;
    }
  }

  String testTraverse(){
    String result = "";
    testVisit();
 
    for(ExpressionNode node in this.siblings){
      result += " sibling: ${node.testTraverse()}";
    }
    
    for(ExpressionNode node in this.children){
      result += " child: ${node.testTraverse()}";
    }
    
    return "$result\n";
  }
  
  String testVisit(){
    return " Kind: $kind";
  }
  
  
}
