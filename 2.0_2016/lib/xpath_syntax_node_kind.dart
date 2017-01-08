part of xpath.dart;

class XpathSyntaxNodeKind {
  static const int
  UNDEFINED = -1,
  ETNK_STEP = 0,      
  ETNK_DOUBLE_STEP = 1, 
  ETNK_FORWARD_AXIS = 2,
  ETNK_REVERSE_AXIS = 3,
  ETNK_NAME_TEST = 4,
  ETNK_NODE_TEST = 5,
  ETNK_LITERAL = 6,
  ETNK_EXPR_SEQUENCE = 7,
  ETNK_FUNCTION_CALL = 8,
  ETNK_PATH_EXPR = 9,
  ETNK_VARIABLE = 10,
  ETNK_PREDICATE = 11;
  int value = UNDEFINED;
  XpathSyntaxNodeKind.set(this.value);
  operator ==(var other) {
    if(other.runtimeType == int){
      return this.value == other;
    }
    else if(other.runtimeType == XpathSyntaxNodeKind){
      return this.value == other.value;
    }
    else return false;
  }
}
