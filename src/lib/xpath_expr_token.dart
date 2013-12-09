part of xpath.dart;

class XpathExprToken {
  XpathTokenKind kind = new XpathTokenKind.set(XpathTokenKind.XXXTODOXXX);
  XpathTokenName name = new XpathTokenName.set(XpathTokenName.ANCESTOR_AXIS);
  XpathLexicalState state = new XpathLexicalState.set(XpathLexicalState.DEFAULT_STATE);
  XpathLexicalState nextState = new XpathLexicalState.set(XpathLexicalState.DEFAULT_STATE);
  int priority = 0; 
  XpathExprToken();  
  XpathExprToken.set(this.kind, this.name, this.state, this.nextState, this.priority);
}