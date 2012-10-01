
class XpathLexicalState {
  static const int 
    DEFAULT_STATE = 0,
    OPERATOR_STATE = 1,
    QNAME_STATE = 2,
    ITEMTYPE_STATE = 3,
    VARNAME_STATE = 4;
  int value = DEFAULT_STATE;
  XpathLexicalState.set(this.value);
  operator ==(XpathLexicalState other) => this.value == other.value;
}
