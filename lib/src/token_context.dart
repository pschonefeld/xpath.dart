part of xpath_dart;

class TokenContext {
  TokenKind kind = TokenKind.DEFAULT;
  TokenName name = TokenName.ANCESTOR_AXIS;
  LexicalState state = LexicalState.DEFAULT_STATE;
  LexicalState toState = LexicalState.DEFAULT_STATE;
  TokenKind priority = TokenKind.DEFAULT;
  TokenContext(this.kind, this.name, this.state, this.toState, this.priority);
}
