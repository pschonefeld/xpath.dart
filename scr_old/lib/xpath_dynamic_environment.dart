
class XpathDynamicEnvironment {
  
  static XpathDynamicEnvironment _instance;  
  XpathStaticEnvironment staticEnvironment;
  Map<String, XpathVariable> variables = {};
  XpathSequence input, result, focus; //focus is the sequence that contains the context item  
  List<XpathItem> contextItem = [];
  List<int> contextPosition = [];
  List<int> contextSize = [];
  bool filterMode = false;
  
  XpathLexicalState state = new XpathLexicalState.set(XpathLexicalState.DEFAULT_STATE);
  Map<String, int> tokens = new Map<String,int>();
  
  XpathDynamicEnvironment._internal();
  
  factory XpathDynamicEnvironment(XpathSequence input, XpathSequence result) {
    if (_instance == null) {
      _instance = new XpathDynamicEnvironment._internal();
      _instance.staticEnvironment = new XpathStaticEnvironment();
      _instance.initVariables();
    }
    _instance.input = input;
    _instance.result = result;
    _instance.contextItem.add(input.items[0]);
    _instance.contextPosition.add(0);
    _instance.contextSize.add(input.items.length);
    return _instance;
  }
  
  void initVariables(){ 

    XsdType itemType = _instance.staticEnvironment.types["dm:item"];
    XsdType nodeType = _instance.staticEnvironment.types["dm:node"];

    _instance.variables["fs:dot"] = new XpathVariable("fs:dot",itemType,null);
    
    //TODO: the rest!
  }
  
  void setVariable(String qname, XsdType type, var value){
    _instance.variables[qname] = new XpathVariable(qname,type,value);
  }  
  
}
