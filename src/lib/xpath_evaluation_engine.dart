
class XpathEvaluationEngine {
 
  const int XPATH_NUM_KNOWN_BASIC_TOKENS = 40;
  const int XPATH_MAX_PATTERN_LOOKAHEAD = 3;  

  static XpathEvaluationEngine _instance;  
  
  Map<String, int> tokens = {};
  List<XpathLexemePattern> patterns = [];
  
  List<int>               pass1Expr = []; //tokenize into basic lexemes
  List<XpathPatternItem>  pass2Expr = []; //normalise white space
  List<XpathPatternItem>  pass2ExprUsed = []; //account for used patterns
  List<XpathToken>        pass3Expr = []; //tokens with state

  List<XpathToken> exprStack = []; //TODO:  
  XpathExpressionNode exprTree;
  
  //Dictionaries
  Map<String, XpathTokenContext> dictDefault = {};
  Map<String, XpathTokenContext> dictOperator = {};
  Map<String, XpathTokenContext> dictQName = {};
  Map<String, XpathTokenContext> dictItemType = {};
  Map<String, XpathTokenContext> dictVarName = {};
  
  int _tokenParseCount;
  int _state;
  XpathToken currentToken;
  int _pass1Count;
  bool isInError = false;
  String ErrorMsg = "";
  
  XpathEvaluationEngine._internal(){
    _initDefaultDictionary();
    _initOperatorDictionary();
    _initQNameDictionary();
    _initItemTypeDictionary();
    _initVarNameDictionary();
    _initTokens();
    _initLexemePatterns();    
  }
  
  factory XpathEvaluationEngine() {
    if(_instance==null){
      _instance = new XpathEvaluationEngine._internal();
    }
    _instance.exprTree = new XpathExpressionNode.root();   
    return _instance;
  }

  /**
   * initialises and calls methods to perform evaluation of expression:
   *
   * * reutrn a sequence of XpathItems as the output of the XPath Expression
   */
  XpathSequence doXPath(XpathSequence input, String expr){
    XpathSequence result = new XpathSequence();
    XpathStaticEnvironment staticEnv = new XpathStaticEnvironment();
    XpathDynamicEnvironment dynamicEnv = new XpathDynamicEnvironment(input, result);
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
    this.normaliseWhiteSpace(); //second pass ...TODO: at the moment this actually deletes ws??
    this.tokenize(); //third pass
    if(this.Pass2Expr.size()!=this.Pass2ExprUsed.size()){
      this.IsInError = true;
      this.ErrorMsg = "";
      for(int i = 0; i < this.Pass2Expr.size();i++){
        boolean found = false;
        for(int j = 0; j < this.Pass2ExprUsed.size(); j++){
          if(((_PatternItem)this.Pass2Expr.get(i)).OriginalPosition == ((_PatternItem)this.Pass2ExprUsed.get(j)).OriginalPosition){
            found = true;
            break;
          }
        }
        if(found){
          this.ErrorMsg += getTokenName(i);
        }
        else this.ErrorMsg += "<span style='color:red'>"+getTokenName(i)+"</span>";
      }
    }
    if(!this.IsInError){
      //PARSE
      this.BuildExprTree();
    }
  }
  
  void buildBasicLexeme(String expr){
    var char; 
    for(_pass1Count=0; _pass1Count<expr.length;_pass1Count++){
      char = expr.splitChars()[_pass1Count];
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
        if(str.splitChars()[_pass1Count+1]!=delimit){
          result = result.concat(str.splitChars()[++_pass1Count]);
        }
        else if(str.splitChars()[_pass1Count+2] == delimit){
          result = result.concat(delimit);
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
  
  //TODO: support all number notations
  String getNumber(String str){
    bool endofword = false;
    String result = "";
    int countPeriod = 0;
    result = result.concat(str.splitChars()[_pass1Count]);
    while(_pass1Count<str.length && !endofword){
      if(_pass1Count!=str.length-1){
        if(str.splitChars()[_pass1Count+1]=='.'){
          if(countPeriod==0) {
            result = result.concat(str.splitChars()[++_pass1Count]);
            countPeriod++;
          }
          else {
            endofword=true; 
          }
        }
        else if(Util.isDigit(str.splitChars()[_pass1Count+1])){
          result = result.concat(str.splitChars()[++_pass1Count]);
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
    result = result.concat(str.splitChars()[_pass1Count]);
    while(_pass1Count<str.length && !endOfWord){
      if(_pass1Count!=str.length-1){
        if(isKnownSymbol(str,_pass1Count+1)) {
          if(str.splitChars()[_pass1Count+1]=='-' || str.splitChars()[_pass1Count+1]=='.') {
            result = result.concat(str.splitChars()[++_pass1Count]);
          }
          else endOfWord=true;
        }
        else result = result.concat(str.splitChars()[++_pass1Count]);
      }
      else endOfWord=true;
    }
    return result;
  }
  
  bool isKnownSymbol(String str, int pos){
    String key = str.splitChars()[pos];
    if(this.tokens[key]!=null)
      return this.tokens[key]<=XPATH_NUM_KNOWN_BASIC_TOKENS?true:false;
    else 
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
    this.pass2Expr.add(new XpathPatternItem(this.pass1Expr[startPos],0));
    
    int pos = 0;
    //collapse contained ws 
    for(var i = startPos; i<this.pass1Expr.length; i++){
      startPos = i+1;     
      if(!isWhitespace(this.pass1Expr[i])) {
        this.pass2Expr.add(new XpathPatternItem(this.pass1Expr[startPos],++pos));
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
    this._state = XpathLexicalState.DEFAULT_STATE;
    List<XpathToken> tokens = new List<XpathToken>();
    for(_tokenParseCount=0;_tokenParseCount<this.pass2Expr.length;_tokenParseCount++){
      tokens.clear();
      tokens = getPatternMatch();
      if(tokens != null){ 
        this.pass3Expr.addAll(tokens);
      }
    }
  }

  List<XpathToken> getPatternMatch(){
    
    //TODO: a test to see if all elements in the expression pass have been tokenized.
    List<XpathToken> result = []; //GWT Compile
    int startCount = _tokenParseCount;
    int lookahead = ((_tokenParseCount+XPATH_MAX_PATTERN_LOOKAHEAD)>=this.pass2Expr.length)?
            this.pass2Expr.length-(_tokenParseCount+1):
            XPATH_MAX_PATTERN_LOOKAHEAD;
    int jumpahead = 0;
    
    List<XpathPatternItem> originalPattern = [], patternBuffer = [];
    XpathPatternItem t; 
    bool match = false;
    for(int i = 0; i<=lookahead; i++){
      t = this.pass2Expr[_tokenParseCount+i];
      originalPattern.add(t);
      if(t.value>XPATH_NUM_KNOWN_BASIC_TOKENS) {
        t = new XpathPatternItem(classifyUnknownLexeme(t.value),t.value);
      }
      patternBuffer.add(t);
    }

    Iterator it; 
    do {
      it = this.patterns.iterator();       
      while(it.hasNext()){
        XpathLexemePattern i = it.next();
        if(isPatternBufferAPattern(patternBuffer,i.pattern)){
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
      it = this.patterns.iterator();
      bool foundToken = false;
      while(it.hasNext() && !foundToken)  {
        XpathLexemePattern current = it.next();
        if(isPatternBufferAPattern(patternBuffer,current.pattern)){
          foundToken = false; //must not add two tokens for the same pattern
                    //this is important in the case where a token sets
                    //the state to a value equal to another token
                    //in the token list for the pattern.
          this.pass2ExprUsed.addAll(patternBuffer); //account for used symbols
          for(int i=0;i<current.tokens.length;i++){
            if(this._state == current.tokens[i].context.state && !foundToken){
              foundToken = true;
              this._state = current.tokens[i].context.toState;
              result.add(new XpathToken(new XpathPatternContextPair(current.tokens[i].pattern, current.tokens[i].context)));
              String tokenName = current.tokens[i].pattern;
              String name = "";
              String precedingToken = this.pass3Expr.length > 0? this.pass3Expr.last().item.pattern : "";
              if(tokenName=="LocalPart"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ||
                  (current.tokens[i].context.state==XpathLexicalState.DEFAULT_STATE) ){
                  //It's ok to insert token here because it will not effect state.
                  result.insertRange(0, 1, getChildAxisTokenEntry());
                }
                result.last().info.add(new XpathTokenInfo());
                name = getLexemeTokenString(originalPattern[0].value);
                result.last().info.last().value = name;
                result.last().info.last().type = "string";
              }
              else if(tokenName=="StringLiteral"){ 
                result.last().info.add(new XpathTokenInfo());
                name = getLexemeTokenString(originalPattern[0].value);
                result.last().info.last().value = name;
                result.last().info.last().type = "string";
              }
              else if(tokenName=="IntegerLiteral"){
                if(precedingToken=="["){
                  //abreviation somenode[5] => somenode[position()=5]
                  XpathTokenContext jt = this.dictOperator["="];
                  if(jt!=null){
                    result.insertRange(0, 1,new XpathToken(new XpathPatternContextPair("=",jt)));
                  }
                  jt = this.dictDefault[")"];
                  if(jt!=null){
                    result.insertRange(0, 1,new XpathToken(new XpathPatternContextPair(")",jt)));
                  }
                  XpathToken te = getFunctionCallTokenEntry(XpathTokenName.QNAME_CALL);
                  te.info.add(new XpathTokenInfo());
                  name = "fn";
                  te.info.last().value = name;
                  te.info.last().type = "string";
                  te.info.add(new XpathTokenInfo());
                  name = "position";
                  te.info.last().value = name;
                  te.info.last().type = "string";
                  result.insertRange(0,1,te);
                }
                result.last().info.add(new XpathTokenInfo());
                name = getLexemeTokenString(originalPattern[0].value);
                result.last().info.last().value = int.parse(name);
                result.last().info.last().type = "integer";
              }
              else if(tokenName=="DoubleLiteral"){ 
                result.last().info.add(new XpathTokenInfo());
                name = getLexemeTokenString(originalPattern[0].value);
                result.last().info.last().value = double.parse(name);
                result.last().info.last().type = "double";
              }
              else if(tokenName=="NCName:NCName"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ){
                  result.add(0,getChildAxisTokenEntry());
                }
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(0)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(2)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
              }
              else if(tokenName=="*"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ){
                  result.add(0,GetChildAxisTokenEntry());
                }
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
              }
              else if(tokenName=="NCName:*"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[")||
                  (precedingToken=="")){
                  result.add(0,GetChildAxisTokenEntry());
                }
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(0)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
              }
              else if(tokenName=="*:NCName"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[")  ||
                  (precedingToken=="") ){
                  result.add(0,GetChildAxisTokenEntry());
                }
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(2)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
              }
              else if(tokenName=="NCName:NCName("){
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(0)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(2)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
              }
              else if(tokenName=="LocalPart("){
                ((_XPathToken)result.lastElement()).Info.add(new _XPathTokenInfo());
                name = GetLexemeTokenString(((_PatternItem)originalPattern.get(0)).Value);
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Value = name;
                ((_XPathTokenInfo)((_XPathToken)result.lastElement()).Info.lastElement()).Type = "string";
              }
              else if(tokenName=="node()" || 
                  tokenName=="text()" || 
                  tokenName=="comment()" || 
                  tokenName=="processing-instruction()"){
                if( (precedingToken=="/") || 
                  (precedingToken=="//") ||
                  (precedingToken=="[") ||
                  (precedingToken=="") ||
                  (((_PatternContextPair)current.TokenMap.get(i)).Context.State==_XPathLexicalState.DEFAULT_STATE) ){
                  //It's ok to insert token here because it will
                  //not effect state.
                  result.add(0,GetChildAxisTokenEntry());
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
  
  XpathToken getFunctionCallTokenEntry(int name){
    XpathToken result;
    XpathTokenContext token = null;
    String strName = "";
    switch(name){
      case XpathTokenName.QNAME_CALL:
        strName = "NCName:NCName(";
        token = this.dictDefault[strName];
        break;
      case XpathTokenName.LOCALNAME_CALL:
        strName = "LocalPart(";       
        token = this.dictDefault["LocalPart("];
        break;
    }
    if(token!=null){
      result = new XpathToken(new XpathPatternContextPair(strName,token));
    }
    return result;    
  }
  
  XpathToken getChildAxisTokenEntry(){
    return new XpathToken(new XpathPatternContextPair("child::",this.dictQName["child::"]));
  }  
  
  bool isPatternBufferAPattern(List<XpathPatternItem> p1, List<int> p2){
    bool result = true;
    if(p1.length!=p2.length){
      result = false;
    }
    if(result==true){
      for(int i = 0; i<p1.length; i++) {
        if(p1[i].value!=p2[i]) {
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
    if(Util.isLetter(tokenStr.splitChars()[0])) {
      result = 0;
    }
    else if(tokenStr.splitChars()[0]=='"' || tokenStr.splitChars()[0]=="'") {
      result = -1;
    }
    else if(Util.isDigit(tokenStr.splitChars()[0])){
      result = -2;
    }
    return result;    
  }
  
  String getLexemeTokenString(int id){
    String result;
    if(this.tokens.containsValue(id)){
      for(String key in this.tokens.getKeys()){
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
    
    this.dictDefault["("] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LEFTPAREN,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictDefault[")"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.RIGHTPAREN,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);

    // "StringLiteral" 
    this.dictDefault["StringLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.STRING_LITERAL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["IntegerLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.INTEGER_LITERAL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["DecimalLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DECIMAL_LITERAL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["DoubleLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DOUBLE_LITERAL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);

    //steps
    this.dictDefault["/"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FORWARDSLASH,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.QNAME_STATE,0);
    this.dictDefault["//"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DOUBLE_FORWARDSLASH,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.QNAME_STATE,0);

    // axis
    this.dictDefault["child::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.CHILD_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["descendant::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DESCENDANT_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["parent::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PARENT_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["attribute::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ATTRIBUTE_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.SELF_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["descendant-or-self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DESCENDANT_OR_SELF_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["ancestor::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANCESTOR_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["ancestor-or-self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANCESTOR_OR_SELF_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["following-sibling::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FOLLOWING_SIBLING_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["following::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FOLLOWING_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["preceding::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PRECEDING_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["preceding-sibling::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PRECEDING_SIBLING_AXIS,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.QNAME_STATE,6);
    this.dictDefault["namespace::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.NAMESPACE_AXIS,XpathLexicalState.DEFAULT_STATE, XpathLexicalState.QNAME_STATE,6);

    //names
    this.dictDefault["*"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.WILDCARD,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["NCName:*"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME_WILDCARD,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["*:NCName"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.NAMESPACE_WILDCARD,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["LocalPart"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictDefault["NCName:NCName"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.QNAME,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);

    this.dictDefault["LocalPart("] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME_CALL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,6);
    this.dictDefault["NCName:NCName("] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.QNAME_CALL,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,6);

    //node tests
    this.dictDefault["text()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.TEXT_NODE_TEST,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictDefault["comment()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.COMMENT_NODE_TEST,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictDefault["node()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANY_NODE_TEST,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictDefault["processing-instruction()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PI_NODE_TEST,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);

    //variable prefix
    this.dictDefault["\$"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.VARIABLE_MARKER,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.VARNAME_STATE,0);

    //"," comma delimiter
    this.dictDefault[","] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.COMMA,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);

    //"[" "]" predicates
    this.dictDefault["["] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.OPEN_BRACKET,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictDefault["]"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.CLOSE_BRACKET,XpathLexicalState.DEFAULT_STATE,XpathLexicalState.OPERATOR_STATE,0);

  }

  void _initOperatorDictionary(){
    
    this.dictOperator["("] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LEFTPAREN,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictOperator[")"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.RIGHTPAREN,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);

    this.dictOperator["/"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FORWARDSLASH,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,6);
    this.dictOperator["//"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DOUBLE_FORWARDSLASH,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,6);

    // "StringLiteral" 
    this.dictOperator["StringLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.STRING_LITERAL,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictOperator["IntegerLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.INTEGER_LITERAL,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictOperator["DecimalLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DECIMAL_LITERAL,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictOperator["DoubleLiteral"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DOUBLE_LITERAL,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);

    this.dictOperator["\$"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.VARIABLE_MARKER,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.VARNAME_STATE,0);

    this.dictOperator["*"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.MULTIPLY,XpathLexicalState.OPERATOR_STATE, XpathLexicalState.DEFAULT_STATE,5);

    //"," comma delimiter
    this.dictOperator[","] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.COMMA,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,0);

    //"[" "]" predicates
    this.dictOperator["["] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.OPEN_BRACKET,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictOperator["]"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.CLOSE_BRACKET,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.OPERATOR_STATE,0);

    //"=" equals
    this.dictOperator["="] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.EQUALS,XpathLexicalState.OPERATOR_STATE,XpathLexicalState.DEFAULT_STATE,0);    
    
  }
  
  void _initQNameDictionary(){
    this.dictQName["("] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LEFTPAREN,XpathLexicalState.QNAME_STATE,XpathLexicalState.DEFAULT_STATE,0);
    this.dictQName[")"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.RIGHTPAREN,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);

    //name tests
    this.dictQName["*"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.WILDCARD,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["NCName:*"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME_WILDCARD,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["*:NCName"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.NAMESPACE_WILDCARD,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["LocalPart"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["NCName:NCName"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.QNAME,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);

    //steps
    this.dictQName["/"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FORWARDSLASH,XpathLexicalState.QNAME_STATE,XpathLexicalState.QNAME_STATE,6);
    this.dictQName["//"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DOUBLE_FORWARDSLASH,XpathLexicalState.QNAME_STATE,XpathLexicalState.QNAME_STATE,6);

    //axis
    this.dictQName["child::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.CHILD_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["descendant::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DESCENDANT_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["parent::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PARENT_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["attribute::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ATTRIBUTE_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.SELF_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["descendant-or-self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.DESCENDANT_OR_SELF_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["ancestor::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANCESTOR_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["ancestor-or-self::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANCESTOR_OR_SELF_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["following-sibling::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FOLLOWING_SIBLING_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["following::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.FOLLOWING_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["preceding::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PRECEDING_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["preceding-sibling::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PRECEDING_SIBLING_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);
    this.dictQName["namespace::"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.NAMESPACE_AXIS,XpathLexicalState.QNAME_STATE, XpathLexicalState.QNAME_STATE,6);

    //node tests
    this.dictQName["text()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.TEXT_NODE_TEST,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["comment()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.COMMENT_NODE_TEST,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["node()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.ANY_NODE_TEST,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictQName["processing-instruction()"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.PI_NODE_TEST,XpathLexicalState.QNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);

    //var prefix
    this.dictQName["\$"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.VARIABLE_MARKER,XpathLexicalState.QNAME_STATE,XpathLexicalState.VARNAME_STATE,0);

    //"," comma delimiter
    this.dictQName[","] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.COMMA,XpathLexicalState.QNAME_STATE,XpathLexicalState.DEFAULT_STATE,0);
  }
  
  void _initItemTypeDictionary(){
    this.dictItemType[")"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.RIGHTPAREN,XpathLexicalState.ITEMTYPE_STATE,XpathLexicalState.OPERATOR_STATE,0);    
  }
  
  void _initVarNameDictionary(){
    //rather than create a varname token have included the two acceptable forms of QName
    this.dictVarName["LocalPart"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.LOCALNAME,XpathLexicalState.VARNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);
    this.dictVarName["NCName:NCName"] = new XpathTokenContext(XpathTokenKind.XXXTODOXXX,XpathTokenName.QNAME,XpathLexicalState.VARNAME_STATE,XpathLexicalState.OPERATOR_STATE,0);   
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
      this.patterns.add(new XpathLexemePattern([-1]));
      token = this.dictDefault["StringLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("StringLiteral", token));
      token = this.dictOperator["StringLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("StringLiteral", token));   
      
      // "IntegerLiteral"
      this.patterns.add(new XpathLexemePattern([-2]));
      token = this.dictDefault["IntegerLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("IntegerLiteral", token));
      token = this.dictOperator["IntegerLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("IntegerLiteral", token));  
      
      // "DecimalLiteral"
      this.patterns.add(new XpathLexemePattern([-3]));
      token = this.dictDefault["DecimalLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("DecimalLiteral", token));
      token = this.dictOperator["DecimalLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("DecimalLiteral", token));

      // "DoubleLiteral"
      this.patterns.add(new XpathLexemePattern([-4]));
      token = this.dictDefault["DoubleLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("DoubleLiteral", token));
      token = this.dictOperator["DoubleLiteral"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("DoubleLiteral", token));

      // "/"
      this.patterns.add(new XpathLexemePattern([13]));
      token = this.dictDefault["/"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("/", token));
      token = this.dictQName["/"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("/", token));
      token = this.dictOperator["/"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("/", token));

      // "//"
      this.patterns.add(new XpathLexemePattern([13,13]));
      token = this.dictDefault["//"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("//", token));
      token = this.dictQName["//"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("//", token));
      token = this.dictOperator["//"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("//", token));

      // "@"
      this.patterns.add(new XpathLexemePattern([14]));
      token = this.dictDefault["attribute::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("attribute::", token));
      token = this.dictQName["attribute::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("attribute::", token));

      // "["
      this.patterns.add(new XpathLexemePattern([11]));
      token = this.dictDefault["["];
      this.patterns.last().tokens.add(new XpathPatternContextPair("[", token));
      token = this.dictOperator["["];
      this.patterns.last().tokens.add(new XpathPatternContextPair("[", token));

      // "]"
      this.patterns.add(new XpathLexemePattern([12]));
      token = this.dictDefault["]"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("]", token));
      token = this.dictOperator["]"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("]", token));

      // "NCName" = QName LocalPart
      this.patterns.add(new XpathLexemePattern([0]));
      token = this.dictQName["LocalPart"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("LocalPart", token));
      token = this.dictDefault["LocalPart"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("LocalPart", token));
      token = this.dictVarName["LocalPart"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("LocalPart", token));

      // "NCName:NCName" = QName
      this.patterns.add(new XpathLexemePattern([0,6,0]));
      token = this.dictDefault["NCName:NCName"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("NCName:NCName", token));
      token = this.dictQName["NCName:NCName"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("NCName:NCName", token));
      token = this.dictVarName["NCName:NCName"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("NCName:NCName", token));

      // "*:NCName" = Wildcard Namespace Prefix QName
      this.patterns.add(new XpathLexemePattern([17,6,0]));
      token = this.dictDefault["*:NCName"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("*:NCName", token));
      token = this.dictQName["*:NCName"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("*:NCName", token));

      // "NCName:*" = Wildcard Local Name for given namespace prefix
      this.patterns.add(new XpathLexemePattern([0,6,17]));
      token = this.dictQName["NCName:*"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("NCName:*", token));

      // "*" = QName wildcard ...everything
      this.patterns.add(new XpathLexemePattern([17]));
      token = this.dictDefault["*"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("*", token));
      token = this.dictQName["*"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("*", token));
      // ....as multiplication operator
      token = this.dictOperator["*"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("*", token));

      // "child::"
      this.patterns.add(new XpathLexemePattern([23,6,6]));
      token = this.dictDefault["child::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("child::", token));
      token = this.dictQName["child::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("child::", token));

      // "self::"
      this.patterns.add(new XpathLexemePattern([27,6,6]));
      token = this.dictDefault["self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("self::", token));
      token = this.dictQName["self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("self::", token));

      // "descendant::"
      this.patterns.add(new XpathLexemePattern([24,6,6]));
      token = this.dictDefault["descendant::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("descendant::", token));
      token = this.dictQName["descendant::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("descendant::", token));

      // "parent::"
      this.patterns.add(new XpathLexemePattern([25,6,6]));
      token = this.dictDefault["parent::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("parent::", token));
      token = this.dictQName["parent::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("parent::", token));

      // "attribute::"
      this.patterns.add(new XpathLexemePattern([26,6,6]));
      token = this.dictDefault["attribute::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("attribute::", token));
      token = this.dictQName["attribute::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("attribute::", token));

      // "ancestor::"
      this.patterns.add(new XpathLexemePattern([28,6,6]));
      token = this.dictDefault["ancestor::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("ancestor::", token));
      token = this.dictQName["ancestor::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("ancestor::", token));

      // "ancestor-or-self::"
      this.patterns.add(new XpathLexemePattern([29,6,6]));
      token = this.dictDefault["ancestor-or-self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("ancestor-or-self::", token));
      token = this.dictQName["ancestor-or-self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("ancestor-or-self::", token));

      // "preceding::"
      this.patterns.add(new XpathLexemePattern([30,6,6]));
      token = this.dictDefault["preceding::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("preceding::", token));
      token = this.dictQName["preceding::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("preceding::", token));

      // "preceding-sibling::"
      this.patterns.add(new XpathLexemePattern([31,6,6]));
      token = this.dictDefault["preceding-sibling::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("preceding-sibling::", token));
      token = this.dictQName["preceding-sibling::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("preceding-sibling::", token));

      // "descendant-or-self::"
      this.patterns.add(new XpathLexemePattern([32,6,6]));
      token = this.dictDefault["descendant-or-self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("descendant-or-self::", token));
      token = this.dictQName["descendant-or-self::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("descendant-or-self::", token));

      // "following::"
      this.patterns.add(new XpathLexemePattern([33,6,6]));
      token = this.dictDefault["following::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("following::", token));
      token = this.dictQName["following::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("following::", token));

      // "following-sibling::"
      this.patterns.add(new XpathLexemePattern([34,6,6]));
      token = this.dictDefault["following-sibling::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("following-sibling::", token));
      token = this.dictQName["following-sibling::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("following-sibling::", token));

      // "namespace::"
      this.patterns.add(new XpathLexemePattern([35,6,6]));
      token = this.dictDefault["namespace::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("namespace::", token));
      token = this.dictQName["namespace::"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("namespace::", token));

      // text()
      this.patterns.add(new XpathLexemePattern([36,7,8]));
      token = this.dictDefault["text()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("text()", token));
      token = this.dictQName["text()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("text()", token));

      // comment()
      this.patterns.add(new XpathLexemePattern([37,7,8]));
      token = this.dictDefault["comment()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("comment()", token));
      token = this.dictQName["comment()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("comment()", token));

      // node()
      this.patterns.add(new XpathLexemePattern([38,7,8]));
      token = this.dictDefault["node()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("node()", token));
      token = this.dictQName["node()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("node()", token));

      // processing-instruction()
      this.patterns.add(new XpathLexemePattern([39,7,8]));
      token = this.dictDefault["processing-instruction()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("processing-instruction()", token));
      token = this.dictQName["processing-instruction()"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("processing-instruction()", token));

      // variable prefix
      this.patterns.add(new XpathLexemePattern([22]));
      token = this.dictDefault["\$"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("\$", token));
      token = this.dictQName["\$"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("\$", token));
      token = this.dictOperator["\$"];
      this.patterns.last().tokens.add(new XpathPatternContextPair("\$", token));
      
      //TODO:
      //token = this.DictItemType.get("$");
      //((XPathLexemePattern)this.patterns.lastElement()).TokenMap.add(new PatternTokenPair("", token));

      //functions
      // "NCName(" = QName LocalPart (
      this.patterns.add(new XpathLexemePattern([0,7]));
      token = this.dictDefault["LocalPart("];
      this.patterns.last().tokens.add(new XpathPatternContextPair("LocalPart(", token));
      
      // "NCName:NCName(" = QName
      this.patterns.add(new XpathLexemePattern([0,6,0,7]));
      token = this.dictDefault["NCName:NCName("];
      this.patterns.last().tokens.add(new XpathPatternContextPair("NCName:NCName(", token));

      // ","
      this.patterns.add(new XpathLexemePattern([5]));
      token = this.dictDefault[","];
      this.patterns.last().tokens.add(new XpathPatternContextPair(",", token));
      token = this.dictQName[","];
      this.patterns.last().tokens.add(new XpathPatternContextPair(",", token));
      token = this.dictOperator[","];
      this.patterns.last().tokens.add(new XpathPatternContextPair(",", token));

      // "("
      this.patterns.add(new XpathLexemePattern([7]));
      token = this.dictDefault["("];
      this.patterns.last().tokens.add(new XpathPatternContextPair("(", token));
      token = this.dictQName["("];
      this.patterns.last().tokens.add(new XpathPatternContextPair("(", token));
      token = this.dictOperator["("];
      this.patterns.last().tokens.add(new XpathPatternContextPair("(", token));

      // ")"
      this.patterns.add(new XpathLexemePattern([8]));
      token = this.dictDefault[")"];
      this.patterns.last().tokens.add(new XpathPatternContextPair(")", token));
      token = this.dictQName[")"];
      this.patterns.last().tokens.add(new XpathPatternContextPair(")", token));
      token = this.dictOperator[")"];
      this.patterns.last().tokens.add(new XpathPatternContextPair(")", token));
      token = this.dictItemType[")"];
      this.patterns.last().tokens.add(new XpathPatternContextPair(")", token));   
      

    
  }
}
