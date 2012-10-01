
class XpathTokenContext {
  int kind = XpathTokenKind.XXXTODOXXX;
  int name = XpathTokenName.ANCESTOR_AXIS;
  int state = XpathLexicalState.DEFAULT_STATE;
  int toState = XpathLexicalState.DEFAULT_STATE;
  int priority = 0;  
  XpathTokenContext(this.kind, this.name, this.state, this.toState, this.priority);
}
