part of xpath_dart;

class EvaluationEngine {
 
  static const int XPATH_NUM_KNOWN_BASIC_TOKENS = 40;
  static const int XPATH_MAX_PATTERN_LOOKAHEAD = 3;  

  static EvaluationEngine _instance;  
  
  Map<String, int> tokens = {};
  List<LexemePattern> patterns = [];
  
  List<int>         pass1Expr = [];     //tokenize into basic lexemes
  List<int>         pass2Expr = [];     //normalise white space
  List<int>         pass2ExprUsed = []; //account for used patterns
  List<TokenEntry>  pass3Expr = [];     //tokens with state

  List<Token> exprStack = []; //TODO:  
  ExpressionNode exprTree;
  
  //Dictionaries
  Map<String, ExprToken> dictDefault = {};
  Map<String, ExprToken> dictOperator = {};
  Map<String, ExprToken> dictQName = {};
  Map<String, ExprToken> dictItemType = {};
  Map<String, ExprToken> dictVarName = {};
  
  int _tokenParseCount;
  LexicalState _state;
  TokenEntry _currentToken;
  int _pass1Count;
  bool isInError = false;
  String ErrorMsg = "";
  
  EvaluationEngine._internal(){
    _initDefaultDictionary();
    _initOperatorDictionary();
    _initQNameDictionary();
    _initItemTypeDictionary();
    _initVarNameDictionary();
    _initTokens();
    _initLexemePatterns();    
  }
  
  factory EvaluationEngine() {
    if(_instance==null){
      _instance = new EvaluationEngine._internal();
    }
    _instance.exprTree = new ExpressionNode.root();   
    return _instance;
  }

  ///initialises and calls methods to perform evaluation of expression. 
  ///reutrns a sequence of XpathItems as the output of the XPath Expression
  Sequence doXPath(Sequence input, String expr){
    Sequence result = new Sequence();
    StaticEnvironment staticEnv = new StaticEnvironment();
    DynamicEnvironment dynamicEnv = new DynamicEnvironment(input, result);
    parseExpression(expr);
    //if(!EE.IsInError){
    //  result = EE.Evaluate(EE.ExprTree,pInput);
    //}
    //else {
    //  result.AppendItem(new _XPathItem(EE.ErrorMsg, "Error"));
    //}
    
    return result;
  }
  
  void parseExpression(String expr){
    //first pass, convert expression string to an
    //array of basic lexemes. Minimal error checking.
    //SCAN
    this.buildBasicLexeme(expr);
    this.normaliseWhiteSpace(); //second pass ...TODO: this just deletes whitespace??
    this.tokenize(); //third pass
    if(this.pass2Expr.length!=this.pass2ExprUsed.length){
      this.isInError = true;
      this.ErrorMsg = "";
      for(int i = 0; i < this.pass2Expr.length;i++){
        bool found = false;
        for(int j = 0; j < this.pass2ExprUsed.length; j++){
          if((this.pass2Expr[i] as PatternItem).originalPosition == (this.pass2ExprUsed[j] as PatternItem).originalPosition){
            found = true;
            break;
          }
        }
        if(found){
          this.ErrorMsg += "";// getTokenName(i);
        }
        else this.ErrorMsg += "";//"<span style='color:red'>"+getTokenName(i)+"</span>";
      }
    }
    if(!this.isInError){
      //PARSE
      this.buildExprTree();
    }
  }
  
  void buildBasicLexeme(String expr){
    var char; 
    for(_pass1Count=0; _pass1Count<expr.length;_pass1Count++){
      char = expr[_pass1Count];
      int tokenid = this.tokens[char];
      if(tokenid!=null && tokenid <= XPATH_NUM_KNOWN_BASIC_TOKENS){ //this is a known symbol
        this.pass1Expr.add(tokenid);
      }
      else {
        String wordToken = "";
        if(Util.isDigit(char)){
          wordToken = getNumber(expr);
        }
        else if(char=='"'){
          wordToken = getStringLiteral(expr,'"');
        }
        else if(char=="'"){
          wordToken = getStringLiteral(expr,"'");
        }
        else{
          wordToken = getWord(expr);
        }
        if(wordToken!=""){
          tokenid = this.tokens[wordToken];
          if(tokenid!=null){
            this.pass1Expr.add(tokenid); //add to expr list
          }
          else { //create new token
            var newid = this.tokens.length+1;
            this.tokens[wordToken] = newid; 
            this.pass1Expr.add(newid);
          }
        }
      }
    }   
  }  
  
  String getStringLiteral(String str, String delimit){
    String result = "";
    bool endOfWord = false;
    int countQuote = 1;
    while(_pass1Count<str.length && !endOfWord){
      if(_pass1Count!=str.length-1){
        if(str[_pass1Count+1]!=delimit){
          result += str[++_pass1Count];
        }
        else if(str[_pass1Count+2] == delimit){
          result += delimit;
          _pass1Count += 2;
          countQuote += 2;
        }
        else {
          _pass1Count++;
          countQuote++;
          endOfWord=true; 
        }
      }
      else {
        endOfWord=true;
      }
    }
    if(countQuote%2!=0) ; //TODO: throw error unclosed quote.
    return "$delimit$result$delimit";
  }  
  
  //TODO: support number notations
  String getNumber(String str){
    bool endofword = false;
    String result = "";
    int countPeriod = 0;
    result += str[_pass1Count];
    while(_pass1Count<str.length && !endofword){
      if(_pass1Count!=str.length-1){
        if(str[_pass1Count+1]=='.'){
          if(countPeriod==0) {
            result += str[++_pass1Count];
            countPeriod++;
          }
          else {
            endofword=true; 
          }
        }
        else if(Util.isDigit(str[_pass1Count+1])){
          result += str[++_pass1Count];
        }
        else {
          endofword=true;
        }
      }
      else {
        endofword=true;
      }
    }
    return result;
  }
  
  String getWord(String str){ //TODO: better support XML 
    String result = "";
    bool endOfWord = false;
    result += str[_pass1Count];
    while(_pass1Count<str.length && !endOfWord){
      if(_pass1Count!=str.length-1){
        if(isKnownSymbol(str,_pass1Count+1)) {
          if(str[_pass1Count+1]=='-' || str[_pass1Count+1]=='.') {
            result += str[++_pass1Count];
          }
          else endOfWord = true;
        }
        else result += str[++_pass1Count];
      }
      else endOfWord=true;
    }
    return result;
  }
  
  bool isKnownSymbol(String str, int pos){
    String key = str[pos];
    if(this.tokens[key]!=null){
      return this.tokens[key]<=XPATH_NUM_KNOWN_BASIC_TOKENS? true: false;
    }
    return false;
  } 
  
  void normaliseWhiteSpace(){

    var startPos = 0;
    for(var i =0; i<this.pass1Expr.length; i++){
      if(isWhitespace(this.pass1Expr[i])){
        startPos = i+1;
      }
      else {
        break;
      }
    }

    this.pass2Expr.add(this.pass1Expr[startPos]);
    
    int pos = 0;
    //collapse contained ws 
    for(var i = startPos; i<this.pass1Expr.length; i++){
      startPos = i+1;     
      if(!isWhitespace(this.pass1Expr[i])) {
        this.pass2Expr.add(this.pass1Expr[startPos]);
      }
    }
  }  
  
  bool isWhitespace(int lexeme) {
    return lexeme==1 || lexeme==2 || lexeme==3;
  } 
  
  bool isWhiteSpaceChar(String char){
    return ( (char==' ') || (char=='\t') || (char=='\n') );
  }
  
  void tokenize(){
    this._state = LexicalState.DEFAULT_STATE;
    List<TokenEntry> tokens = new List<TokenEntry>();
    for(_tokenParseCount=0;_tokenParseCount<this.pass2Expr.length;_tokenParseCount++){
      tokens.clear();
      tokens = getPatternMatch();
      if(tokens != null){ 
        this.pass3Expr.addAll(tokens);
      }
    }
  }

  void buildExprTree(){
    this.pass3Expr.forEach((TokenEntry t){
      this._currentToken = t;
      this.exprTree = new ExpressionNode();
      this.exprTree.isRoot = true;      
    });
  }


  TokenEntry getChildAxisTokenEntry(){
    return new TokenEntry(new PatternTokenPair("child::",this.dictQName["child::"]));
  }
  
  TokenEntry getFunctionCallTokenEntry(TokenName name){
    ExprToken token = null;
    String sname = "";
    switch(name){
      case TokenName.QNAME_CALL:
        sname = "NCName:NCName(";
        token = this.dictDefault[sname]; //ExprToken
        break;
      case TokenName.LOCALNAME_CALL:
        sname = "LocalPart(";       
        token = this.dictDefault["LocalPart("];
        break;
      default: break; //TODO:
    }
    if(token!=null){
      return new TokenEntry(new PatternTokenPair(sname,token));
    }
    return null;    
  }  

  List<TokenEntry> getPatternMatch(){
    
    //TODO: a test to see if all elements in the expression pass have been tokenized.
    List<TokenEntry> result = []; 
    int startCount = _tokenParseCount;
    int lookahead = ((_tokenParseCount + XPATH_MAX_PATTERN_LOOKAHEAD) >= this.pass2Expr.length)?
            this.pass2Expr.length - (_tokenParseCount+1):
            XPATH_MAX_PATTERN_LOOKAHEAD;
    int jumpahead = 0;
    
    List<int> originalPattern = [], patternBuffer = [];
    int ct; 
    bool match = false;
    for(int i = 0; i<=lookahead; i++){
      int ct = this.pass2Expr[_tokenParseCount+i];
      originalPattern.add(ct);
      if(ct>XPATH_NUM_KNOWN_BASIC_TOKENS) {
        ct = classifyUnknownLexeme(ct);
      }
      patternBuffer.add(ct);
    }

    Iterator<LexemePattern> it; 
    do {
      it = this.patterns.iterator;
      while(it.moveNext()){
        if(isPatternBufferAPattern(patternBuffer,it.current.pattern)){
          match = true;
          jumpahead = lookahead;
          break;
        }
      }
      if(!match) {
        if(patternBuffer.length>0){
          patternBuffer.removeLast();
        }
        lookahead--;
      }
    } while (!match && lookahead>=0);

    if(match) {
      it = this.patterns.iterator;
      bool foundToken = false;
      while(it.moveNext() && !foundToken)  {
        LexemePattern current = it.current;
        if(isPatternBufferAPattern(patternBuffer,current.pattern)){
          foundToken = false; //must not add two tokens for the same pattern
                    //this is important in the case where a token sets
                    //the state to a value equal to another token
                    //in the token list for the pattern.
          this.pass2ExprUsed.addAll(patternBuffer); //account for used symbols
          for(int i=0;i<current.tokens.length;i++){
            if(this._state == current.tokens[i].token.state && !foundToken){
              foundToken = true;
              this._state = current.tokens[i].token.nextState;
              //result.add(new TokenEntry(new PatternTokenPair(((PatternTokenPair)current.TokenMap.get(i)).Pattern,((PatternTokenPair)              
              result.add(new TokenEntry(new PatternTokenPair(current.tokens[i].pattern, current.tokens[i].token)));
              String tokenName = current.tokens[i].pattern;
              String name = "";
              String precedingToken = this.pass3Expr.length > 0? this.pass3Expr.last.token.pattern : "";
              if(tokenName=="LocalPart"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ||
                  (current.tokens[i].token.state == LexicalState.DEFAULT_STATE) ){
                  //It's ok to insert token here because it will not effect state.
                  result.insert(0,getChildAxisTokenEntry());
                }
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="StringLiteral"){ 
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="IntegerLiteral"){
                if(precedingToken=="["){
                  //abreviation somenode[5] => somenode[position()=5]
                  ExprToken jt = this.dictOperator["="];
                  if(jt!=null){
                    result.insert(0, new TokenEntry(new PatternTokenPair("=",jt)));
                  }
                  jt = this.dictDefault[")"];
                  if(jt!=null){
                    result.insert(0, new TokenEntry(new PatternTokenPair(")",jt)));
                  }
                  TokenEntry te = getFunctionCallTokenEntry(TokenName.QNAME_CALL);
                  te.info.add(new TokenInfo());
                  name = "fn";
                  te.info.last.value = name;
                  te.info.last.type = "string";
                  te.info.add(new TokenInfo());
                  name = "position";
                  te.info.last.value = name;
                  te.info.last.type = "string";
                  result.insert(0,te);
                }
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = int.parse(name);
                result.last.info.last.type = "integer";
              }
              else if(tokenName=="DoubleLiteral"){ 
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = double.parse(name);
                result.last.info.last.type = "double";
              }
              else if(tokenName=="NCName:NCName"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ){
                  result.insert(0,getChildAxisTokenEntry());
                }
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[2]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="*"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ){
                  result.insert(0,getChildAxisTokenEntry());
                }
                result.last.info.add(new TokenInfo());
              }
              else if(tokenName=="NCName:*"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[")||
                  (precedingToken=="")){
                  result.insert(0,getChildAxisTokenEntry());
                }
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="*:NCName"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[")  ||
                  (precedingToken=="") ){
                  result.insert(0,getChildAxisTokenEntry());
                }
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[2]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="NCName:NCName("){
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[2]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="LocalPart("){
                result.last.info.add(new TokenInfo());
                name = getLexemeTokenString(originalPattern[0]);
                result.last.info.last.value = name;
                result.last.info.last.type = "string";
              }
              else if(tokenName=="node()" || 
                  tokenName=="text()" || 
                  tokenName=="comment()" || 
                  tokenName=="processing-instruction()"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ||
                  (current.tokens[i].token.state == LexicalState.DEFAULT_STATE)){
                  //It's ok to insert token here because it will
                  //not effect state.
                  result.insert(0,getChildAxisTokenEntry());
                }
              }
            }
          }
        }
      }
    }
    _tokenParseCount = startCount + jumpahead;
    return result;
  }
  
  bool isPatternBufferAPattern(List<int> p1, List<int> p2){
    bool result = true;
    if(p1.length!=p2.length){
      result = false;
    }
    if(result==true){
      for(int i = 0; i<p1.length; i++) {
        if(p1[i]!=p2[i]) {
          result = false;
          break;
        }
      }
    }
    return result;
  }  
  
  int classifyUnknownLexeme(int i){
    int result = 1;
    String tokenStr = this.getLexemeTokenString(i);
    if(Util.isLetter(tokenStr[0])) {
      result = 0;
    }
    else if(tokenStr[0]=='"' || tokenStr[0]=="'") {
      result = -1;
    }
    else if(Util.isDigit(tokenStr[0])){
      result = -2;
    }
    return result;    
  }
  
  String getLexemeTokenString(int id){
    String result;
    if(this.tokens.containsValue(id)){
      for(String key in this.tokens.keys){
        if(this.tokens[key]==id){
          result = key;
          break;
        }
      }
    }
    return result;    
  }

  //** INITITALIZATION (on _instance once only)

  void _initDefaultDictionary(){
    
    this.dictDefault["("] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LEFTPAREN,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictDefault[")"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.RIGHTPAREN,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);

    // "StringLiteral" 
    this.dictDefault["StringLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.STRING_LITERAL,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["IntegerLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.INTEGER_LITERAL,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["DecimalLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DECIMAL_LITERAL,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["DoubleLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DOUBLE_LITERAL,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);

    //steps
    this.dictDefault["/"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FORWARDSLASH,LexicalState.DEFAULT_STATE,LexicalState.QNAME_STATE,0);
    this.dictDefault["//"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DOUBLE_FORWARDSLASH,LexicalState.DEFAULT_STATE,LexicalState.QNAME_STATE,0);

    // axis
    this.dictDefault["child::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.CHILD_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["descendant::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DESCENDANT_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["parent::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PARENT_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["attribute::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ATTRIBUTE_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.SELF_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["descendant-or-self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DESCENDANT_OR_SELF_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["ancestor::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANCESTOR_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["ancestor-or-self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANCESTOR_OR_SELF_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["following-sibling::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FOLLOWING_SIBLING_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["following::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FOLLOWING_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["preceding::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PRECEDING_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);
    this.dictDefault["preceding-sibling::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PRECEDING_SIBLING_AXIS,LexicalState.DEFAULT_STATE,LexicalState.QNAME_STATE,6);
    this.dictDefault["namespace::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.NAMESPACE_AXIS,LexicalState.DEFAULT_STATE, LexicalState.QNAME_STATE,6);

    //names
    this.dictDefault["*"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.WILDCARD,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["NCName:*"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME_WILDCARD,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["*:NCName"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.NAMESPACE_WILDCARD,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["LocalPart"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictDefault["NCName:NCName"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.QNAME,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);

    this.dictDefault["LocalPart("] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME_CALL,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,6);
    this.dictDefault["NCName:NCName("] = new ExprToken.set(TokenKind.DEFAULT,TokenName.QNAME_CALL,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,6);

    //node tests
    this.dictDefault["text()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.TEXT_NODE_TEST,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictDefault["comment()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.COMMENT_NODE_TEST,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictDefault["node()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANY_NODE_TEST,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictDefault["processing-instruction()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PI_NODE_TEST,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);

    //variable prefix
    this.dictDefault["\$"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.VARIABLE_MARKER,LexicalState.DEFAULT_STATE,LexicalState.VARNAME_STATE,0);

    //"," comma delimiter
    this.dictDefault[","] = new ExprToken.set(TokenKind.DEFAULT,TokenName.COMMA,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);

    //"[" "]" predicates
    this.dictDefault["["] = new ExprToken.set(TokenKind.DEFAULT,TokenName.OPEN_BRACKET,LexicalState.DEFAULT_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictDefault["]"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.CLOSE_BRACKET,LexicalState.DEFAULT_STATE,LexicalState.OPERATOR_STATE,0);

  }

  void _initOperatorDictionary(){
    
    this.dictOperator["("] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LEFTPAREN,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictOperator[")"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.RIGHTPAREN,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);

    this.dictOperator["/"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FORWARDSLASH,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,6);
    this.dictOperator["//"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DOUBLE_FORWARDSLASH,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,6);

    // "StringLiteral" 
    this.dictOperator["StringLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.STRING_LITERAL,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictOperator["IntegerLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.INTEGER_LITERAL,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictOperator["DecimalLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DECIMAL_LITERAL,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictOperator["DoubleLiteral"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DOUBLE_LITERAL,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);

    this.dictOperator["\$"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.VARIABLE_MARKER,LexicalState.OPERATOR_STATE,LexicalState.VARNAME_STATE,0);

    this.dictOperator["*"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.MULTIPLY,LexicalState.OPERATOR_STATE, LexicalState.DEFAULT_STATE,5);

    //"," comma delimiter
    this.dictOperator[","] = new ExprToken.set(TokenKind.DEFAULT,TokenName.COMMA,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,0);

    //"[" "]" predicates
    this.dictOperator["["] = new ExprToken.set(TokenKind.DEFAULT,TokenName.OPEN_BRACKET,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictOperator["]"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.CLOSE_BRACKET,LexicalState.OPERATOR_STATE,LexicalState.OPERATOR_STATE,0);

    //"=" equals
    this.dictOperator["="] = new ExprToken.set(TokenKind.DEFAULT,TokenName.EQUALS,LexicalState.OPERATOR_STATE,LexicalState.DEFAULT_STATE,0);    
    
  }
  
  void _initQNameDictionary(){
    this.dictQName["("] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LEFTPAREN,LexicalState.QNAME_STATE,LexicalState.DEFAULT_STATE,0);
    this.dictQName[")"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.RIGHTPAREN,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);

    //name tests
    this.dictQName["*"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.WILDCARD,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["NCName:*"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME_WILDCARD,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["*:NCName"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.NAMESPACE_WILDCARD,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["LocalPart"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["NCName:NCName"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.QNAME,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);

    //steps
    this.dictQName["/"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FORWARDSLASH,LexicalState.QNAME_STATE,LexicalState.QNAME_STATE,6);
    this.dictQName["//"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DOUBLE_FORWARDSLASH,LexicalState.QNAME_STATE,LexicalState.QNAME_STATE,6);

    //axis
    this.dictQName["child::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.CHILD_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["descendant::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DESCENDANT_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["parent::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PARENT_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["attribute::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ATTRIBUTE_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.SELF_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["descendant-or-self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.DESCENDANT_OR_SELF_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["ancestor::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANCESTOR_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["ancestor-or-self::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANCESTOR_OR_SELF_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["following-sibling::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FOLLOWING_SIBLING_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["following::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.FOLLOWING_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["preceding::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PRECEDING_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["preceding-sibling::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PRECEDING_SIBLING_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);
    this.dictQName["namespace::"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.NAMESPACE_AXIS,LexicalState.QNAME_STATE, LexicalState.QNAME_STATE,6);

    //node tests
    this.dictQName["text()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.TEXT_NODE_TEST,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["comment()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.COMMENT_NODE_TEST,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["node()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.ANY_NODE_TEST,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictQName["processing-instruction()"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.PI_NODE_TEST,LexicalState.QNAME_STATE,LexicalState.OPERATOR_STATE,0);

    //var prefix
    this.dictQName["\$"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.VARIABLE_MARKER,LexicalState.QNAME_STATE,LexicalState.VARNAME_STATE,0);

    //"," comma delimiter
    this.dictQName[","] = new ExprToken.set(TokenKind.DEFAULT,TokenName.COMMA,LexicalState.QNAME_STATE,LexicalState.DEFAULT_STATE,0);
  }
  
  void _initItemTypeDictionary(){
    this.dictItemType[")"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.RIGHTPAREN,LexicalState.ITEMTYPE_STATE,LexicalState.OPERATOR_STATE,0);    
  }
  
  void _initVarNameDictionary(){
    //rather than create a varname token have included the two acceptable forms of QName
    this.dictVarName["LocalPart"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.LOCALNAME,LexicalState.VARNAME_STATE,LexicalState.OPERATOR_STATE,0);
    this.dictVarName["NCName:NCName"] = new ExprToken.set(TokenKind.DEFAULT,TokenName.QNAME,LexicalState.VARNAME_STATE,LexicalState.OPERATOR_STATE,0);   
  }
  
  void _initTokens(){
    //reserve 0 for NCNames
    this.tokens[" "] = 1;
    this.tokens["\t"] = 2;
    this.tokens["\n"] = 3;
    this.tokens["."] = 4;
    this.tokens["]"] = 5;
    this.tokens[":"] = 6;
    this.tokens["("] = 7;
    this.tokens[")"] = 8;
    this.tokens["{"] = 9;
    this.tokens["}"] = 10;
    this.tokens["["] = 11;
    this.tokens["]"] = 12;
    this.tokens["/"] = 13;
    this.tokens["@"] = 14;
    this.tokens["-"] = 15;
    this.tokens["+"] = 16;
    this.tokens["*"] = 17;
    this.tokens["="] = 18;
    this.tokens["<"] = 19;
    this.tokens[">"] = 20;
    this.tokens["?"] = 21;
    this.tokens["\$"] = 22;

    this.tokens["child"] = 23;
    this.tokens["descendant"] = 24;
    this.tokens["parent"] = 25;
    this.tokens["attribute"] = 26;
    this.tokens["self"] = 27;
    this.tokens["ancestor"] = 28;
    this.tokens["ancestor-or-self"] = 29;
    this.tokens["preceding"] = 30;
    this.tokens["preceding-sibling"] = 31;
    this.tokens["descendant-or-self"] = 32;
    this.tokens["following"] = 33;
    this.tokens["following-sibling"] = 34;
    this.tokens["namespace"] = 35;
    
    this.tokens["text"] = 36;
    this.tokens["comment"] = 37;
    this.tokens["node"] = 38;
    this.tokens["processing-instruction"] = 39;
    
    this.tokens[";"] = 40;

    //Reserved Function Names
    //this.tokens["if"] = 41;
    //this.tokens["typeswitch"] = 42;
    //this.tokens["item"] = 43;
    //this.tokens["element"] = 44;
    //this.tokens["key"] = 45;// was...this.tokens["id"] = 45;
    //this.tokens["key"] = 46;
  }
  
  void _initLexemePatterns(){
    
      var token;
      var pattern;
      
      // "StringLiteral"
      this.patterns.add(new LexemePattern([-1]));
      token = this.dictDefault["StringLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("StringLiteral", token));
      token = this.dictOperator["StringLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("StringLiteral", token));   
      
      // "IntegerLiteral"
      this.patterns.add(new LexemePattern([-2]));
      token = this.dictDefault["IntegerLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("IntegerLiteral", token));
      token = this.dictOperator["IntegerLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("IntegerLiteral", token));  
      
      // "DecimalLiteral"
      this.patterns.add(new LexemePattern([-3]));
      token = this.dictDefault["DecimalLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("DecimalLiteral", token));
      token = this.dictOperator["DecimalLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("DecimalLiteral", token));

      // "DoubleLiteral"
      this.patterns.add(new LexemePattern([-4]));
      token = this.dictDefault["DoubleLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("DoubleLiteral", token));
      token = this.dictOperator["DoubleLiteral"];
      this.patterns.last.tokens.add(new PatternTokenPair("DoubleLiteral", token));

      // "/"
      this.patterns.add(new LexemePattern([13]));
      token = this.dictDefault["/"];
      this.patterns.last.tokens.add(new PatternTokenPair("/", token));
      token = this.dictQName["/"];
      this.patterns.last.tokens.add(new PatternTokenPair("/", token));
      token = this.dictOperator["/"];
      this.patterns.last.tokens.add(new PatternTokenPair("/", token));

      // "//"
      this.patterns.add(new LexemePattern([13,13]));
      token = this.dictDefault["//"];
      this.patterns.last.tokens.add(new PatternTokenPair("//", token));
      token = this.dictQName["//"];
      this.patterns.last.tokens.add(new PatternTokenPair("//", token));
      token = this.dictOperator["//"];
      this.patterns.last.tokens.add(new PatternTokenPair("//", token));

      // "@"
      this.patterns.add(new LexemePattern([14]));
      token = this.dictDefault["attribute::"];
      this.patterns.last.tokens.add(new PatternTokenPair("attribute::", token));
      token = this.dictQName["attribute::"];
      this.patterns.last.tokens.add(new PatternTokenPair("attribute::", token));

      // "["
      this.patterns.add(new LexemePattern([11]));
      token = this.dictDefault["["];
      this.patterns.last.tokens.add(new PatternTokenPair("[", token));
      token = this.dictOperator["["];
      this.patterns.last.tokens.add(new PatternTokenPair("[", token));

      // "]"
      this.patterns.add(new LexemePattern([12]));
      token = this.dictDefault["]"];
      this.patterns.last.tokens.add(new PatternTokenPair("]", token));
      token = this.dictOperator["]"];
      this.patterns.last.tokens.add(new PatternTokenPair("]", token));

      // "NCName" = QName LocalPart
      this.patterns.add(new LexemePattern([0]));
      token = this.dictQName["LocalPart"];
      this.patterns.last.tokens.add(new PatternTokenPair("LocalPart", token));
      token = this.dictDefault["LocalPart"];
      this.patterns.last.tokens.add(new PatternTokenPair("LocalPart", token));
      token = this.dictVarName["LocalPart"];
      this.patterns.last.tokens.add(new PatternTokenPair("LocalPart", token));

      // "NCName:NCName" = QName
      this.patterns.add(new LexemePattern([0,6,0]));
      token = this.dictDefault["NCName:NCName"];
      this.patterns.last.tokens.add(new PatternTokenPair("NCName:NCName", token));
      token = this.dictQName["NCName:NCName"];
      this.patterns.last.tokens.add(new PatternTokenPair("NCName:NCName", token));
      token = this.dictVarName["NCName:NCName"];
      this.patterns.last.tokens.add(new PatternTokenPair("NCName:NCName", token));

      // "*:NCName" = Wildcard Namespace Prefix QName
      this.patterns.add(new LexemePattern([17,6,0]));
      token = this.dictDefault["*:NCName"];
      this.patterns.last.tokens.add(new PatternTokenPair("*:NCName", token));
      token = this.dictQName["*:NCName"];
      this.patterns.last.tokens.add(new PatternTokenPair("*:NCName", token));

      // "NCName:*" = Wildcard Local Name for given namespace prefix
      this.patterns.add(new LexemePattern([0,6,17]));
      token = this.dictQName["NCName:*"];
      this.patterns.last.tokens.add(new PatternTokenPair("NCName:*", token));

      // "*" = QName wildcard ...everything
      this.patterns.add(new LexemePattern([17]));
      token = this.dictDefault["*"];
      this.patterns.last.tokens.add(new PatternTokenPair("*", token));
      token = this.dictQName["*"];
      this.patterns.last.tokens.add(new PatternTokenPair("*", token));
      // ....as multiplication operator
      token = this.dictOperator["*"];
      this.patterns.last.tokens.add(new PatternTokenPair("*", token));

      // "child::"
      this.patterns.add(new LexemePattern([23,6,6]));
      token = this.dictDefault["child::"];
      this.patterns.last.tokens.add(new PatternTokenPair("child::", token));
      token = this.dictQName["child::"];
      this.patterns.last.tokens.add(new PatternTokenPair("child::", token));

      // "self::"
      this.patterns.add(new LexemePattern([27,6,6]));
      token = this.dictDefault["self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("self::", token));
      token = this.dictQName["self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("self::", token));

      // "descendant::"
      this.patterns.add(new LexemePattern([24,6,6]));
      token = this.dictDefault["descendant::"];
      this.patterns.last.tokens.add(new PatternTokenPair("descendant::", token));
      token = this.dictQName["descendant::"];
      this.patterns.last.tokens.add(new PatternTokenPair("descendant::", token));

      // "parent::"
      this.patterns.add(new LexemePattern([25,6,6]));
      token = this.dictDefault["parent::"];
      this.patterns.last.tokens.add(new PatternTokenPair("parent::", token));
      token = this.dictQName["parent::"];
      this.patterns.last.tokens.add(new PatternTokenPair("parent::", token));

      // "attribute::"
      this.patterns.add(new LexemePattern([26,6,6]));
      token = this.dictDefault["attribute::"];
      this.patterns.last.tokens.add(new PatternTokenPair("attribute::", token));
      token = this.dictQName["attribute::"];
      this.patterns.last.tokens.add(new PatternTokenPair("attribute::", token));

      // "ancestor::"
      this.patterns.add(new LexemePattern([28,6,6]));
      token = this.dictDefault["ancestor::"];
      this.patterns.last.tokens.add(new PatternTokenPair("ancestor::", token));
      token = this.dictQName["ancestor::"];
      this.patterns.last.tokens.add(new PatternTokenPair("ancestor::", token));

      // "ancestor-or-self::"
      this.patterns.add(new LexemePattern([29,6,6]));
      token = this.dictDefault["ancestor-or-self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("ancestor-or-self::", token));
      token = this.dictQName["ancestor-or-self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("ancestor-or-self::", token));

      // "preceding::"
      this.patterns.add(new LexemePattern([30,6,6]));
      token = this.dictDefault["preceding::"];
      this.patterns.last.tokens.add(new PatternTokenPair("preceding::", token));
      token = this.dictQName["preceding::"];
      this.patterns.last.tokens.add(new PatternTokenPair("preceding::", token));

      // "preceding-sibling::"
      this.patterns.add(new LexemePattern([31,6,6]));
      token = this.dictDefault["preceding-sibling::"];
      this.patterns.last.tokens.add(new PatternTokenPair("preceding-sibling::", token));
      token = this.dictQName["preceding-sibling::"];
      this.patterns.last.tokens.add(new PatternTokenPair("preceding-sibling::", token));

      // "descendant-or-self::"
      this.patterns.add(new LexemePattern([32,6,6]));
      token = this.dictDefault["descendant-or-self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("descendant-or-self::", token));
      token = this.dictQName["descendant-or-self::"];
      this.patterns.last.tokens.add(new PatternTokenPair("descendant-or-self::", token));

      // "following::"
      this.patterns.add(new LexemePattern([33,6,6]));
      token = this.dictDefault["following::"];
      this.patterns.last.tokens.add(new PatternTokenPair("following::", token));
      token = this.dictQName["following::"];
      this.patterns.last.tokens.add(new PatternTokenPair("following::", token));

      // "following-sibling::"
      this.patterns.add(new LexemePattern([34,6,6]));
      token = this.dictDefault["following-sibling::"];
      this.patterns.last.tokens.add(new PatternTokenPair("following-sibling::", token));
      token = this.dictQName["following-sibling::"];
      this.patterns.last.tokens.add(new PatternTokenPair("following-sibling::", token));

      // "namespace::"
      this.patterns.add(new LexemePattern([35,6,6]));
      token = this.dictDefault["namespace::"];
      this.patterns.last.tokens.add(new PatternTokenPair("namespace::", token));
      token = this.dictQName["namespace::"];
      this.patterns.last.tokens.add(new PatternTokenPair("namespace::", token));

      // text()
      this.patterns.add(new LexemePattern([36,7,8]));
      token = this.dictDefault["text()"];
      this.patterns.last.tokens.add(new PatternTokenPair("text()", token));
      token = this.dictQName["text()"];
      this.patterns.last.tokens.add(new PatternTokenPair("text()", token));

      // comment()
      this.patterns.add(new LexemePattern([37,7,8]));
      token = this.dictDefault["comment()"];
      this.patterns.last.tokens.add(new PatternTokenPair("comment()", token));
      token = this.dictQName["comment()"];
      this.patterns.last.tokens.add(new PatternTokenPair("comment()", token));

      // node()
      this.patterns.add(new LexemePattern([38,7,8]));
      token = this.dictDefault["node()"];
      this.patterns.last.tokens.add(new PatternTokenPair("node()", token));
      token = this.dictQName["node()"];
      this.patterns.last.tokens.add(new PatternTokenPair("node()", token));

      // processing-instruction()
      this.patterns.add(new LexemePattern([39,7,8]));
      token = this.dictDefault["processing-instruction()"];
      this.patterns.last.tokens.add(new PatternTokenPair("processing-instruction()", token));
      token = this.dictQName["processing-instruction()"];
      this.patterns.last.tokens.add(new PatternTokenPair("processing-instruction()", token));

      // variable prefix
      this.patterns.add(new LexemePattern([22]));
      token = this.dictDefault["\$"];
      this.patterns.last.tokens.add(new PatternTokenPair("\$", token));
      token = this.dictQName["\$"];
      this.patterns.last.tokens.add(new PatternTokenPair("\$", token));
      token = this.dictOperator["\$"];
      this.patterns.last.tokens.add(new PatternTokenPair("\$", token));
      
      //TODO:
      //token = this.DictItemType.get("$");
      //((LexemePattern)this.patterns.lastElement()).TokenMap.add(new PatternTokenPair("", token));

      //functions
      // "NCName(" = QName LocalPart (
      this.patterns.add(new LexemePattern([0,7]));
      token = this.dictDefault["LocalPart("];
      this.patterns.last.tokens.add(new PatternTokenPair("LocalPart(", token));
      
      // "NCName:NCName(" = QName
      this.patterns.add(new LexemePattern([0,6,0,7]));
      token = this.dictDefault["NCName:NCName("];
      this.patterns.last.tokens.add(new PatternTokenPair("NCName:NCName(", token));

      // ","
      this.patterns.add(new LexemePattern([5]));
      token = this.dictDefault[","];
      this.patterns.last.tokens.add(new PatternTokenPair(",", token));
      token = this.dictQName[","];
      this.patterns.last.tokens.add(new PatternTokenPair(",", token));
      token = this.dictOperator[","];
      this.patterns.last.tokens.add(new PatternTokenPair(",", token));

      // "("
      this.patterns.add(new LexemePattern([7]));
      token = this.dictDefault["("];
      this.patterns.last.tokens.add(new PatternTokenPair("(", token));
      token = this.dictQName["("];
      this.patterns.last.tokens.add(new PatternTokenPair("(", token));
      token = this.dictOperator["("];
      this.patterns.last.tokens.add(new PatternTokenPair("(", token));

      // ")"
      this.patterns.add(new LexemePattern([8]));
      token = this.dictDefault[")"];
      this.patterns.last.tokens.add(new PatternTokenPair(")", token));
      token = this.dictQName[")"];
      this.patterns.last.tokens.add(new PatternTokenPair(")", token));
      token = this.dictOperator[")"];
      this.patterns.last.tokens.add(new PatternTokenPair(")", token));
      token = this.dictItemType[")"];
      this.patterns.last.tokens.add(new PatternTokenPair(")", token));   
      

    
  }
  

}
