part of xpath_dart;

class ExprToken {
  TokenKind kind = TokenKind.XXXTODOXXX;
  TokenName name = TokenName.ANCESTOR_AXIS;
  LexicalState state = new LexicalState.set(LexicalState.DEFAULT_STATE);
  LexicalState nextState = new LexicalState.set(LexicalState.DEFAULT_STATE);
  int priority = 0; 
  XpathExprToken();  
  XpathExprToken.set(this.kind, this.name, this.state, this.nextState, this.priority);
}