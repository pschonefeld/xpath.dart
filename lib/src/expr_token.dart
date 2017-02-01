part of xpath_dart;

class ExprToken {
  TokenKind kind = TokenKind.XXXTODOXXX;
  TokenName name = TokenName.ANCESTOR_AXIS;
  LexicalState state = LexicalState.DEFAULT_STATE;
  LexicalState nextState = LexicalState.DEFAULT_STATE;
  int priority = 0; 
  ExprToken();
  ExprToken.set(this.kind, this.name, this.state, this.nextState, this.priority);
}