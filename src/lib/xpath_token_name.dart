
class XpathTokenName {
  static const int 
  UNDEFINED = -1,
  ENDEXPR = 0,
  LEFTPAREN = 1,
  RIGHTPAREN = 2,
  STRING_LITERAL = 3,
  INTEGER_LITERAL = 4,
  DECIMAL_LITERAL = 5,
  DOUBLE_LITERAL = 6,
  FORWARDSLASH = 7,
  DOUBLE_FORWARDSLASH = 8,
  CHILD_AXIS = 9,
  DESCENDANT_AXIS = 10,
  PARENT_AXIS = 11,
  ATTRIBUTE_AXIS = 12,
  SELF_AXIS = 13,
  DESCENDANT_OR_SELF_AXIS = 14,
  ANCESTOR_AXIS = 15,
  FOLLOWING_SIBLING_AXIS = 16,
  FOLLOWING_AXIS = 17,
  PRECEDING_AXIS = 18,
  PRECEDING_SIBLING_AXIS = 19,
  NAMESPACE_AXIS = 20,
  ANCESTOR_OR_SELF_AXIS = 21,
  WILDCARD = 22,
  LOCALNAME_WILDCARD = 23,
  NAMESPACE_WILDCARD = 24,
  LOCALNAME = 25,
  QNAME = 26,
  LOCALNAME_CALL = 27,
  QNAME_CALL = 28,
  TEXT_NODE_TEST = 29,
  COMMENT_NODE_TEST = 30,
  ANY_NODE_TEST = 31,
  PI_NODE_TEST = 32,
  VARIABLE_MARKER = 33,
  COMMA = 34,
  MULTIPLY = 35,
  EQUALS = 36,
  OPEN_BRACKET = 37,
  CLOSE_BRACKET = 38;
  int value = UNDEFINED;
  XpathTokenName.set(this.value);  
  operator ==(var other) {
    if(other.runtimeType == int){
      return this.value == other;
    }
    else if(other.runtimeType == XpathTokenName){
      return this.value == other.value;
    }
    else return false;
  }
}
