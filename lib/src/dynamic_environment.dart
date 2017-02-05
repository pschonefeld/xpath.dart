part of xpath_dart;

class DynamicEnvironment {
  
  static DynamicEnvironment _instance;
  StaticEnvironment staticEnvironment;
  Map<String, Variable> variables = {};
  Sequence input, result, focus; //focus is the sequence that contains the context item
  List<Item> contextItem = [];
  List<int> contextPosition = [];
  List<int> contextSize = [];
  bool filterMode = false;
  
  LexicalState state = LexicalState.DEFAULT_STATE;
  Map<String, int> tokens = new Map<String,int>();
  
  DynamicEnvironment._internal();
  
  factory DynamicEnvironment(Sequence input, Sequence result) {
    if (_instance == null) {
      _instance = new DynamicEnvironment._internal();
      _instance.staticEnvironment = new StaticEnvironment();
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

    _instance.variables["fs:dot"] = new Variable("fs:dot",itemType,null);
    
    //TODO: the rest!
  }
  
  void setVariable(String qname, XsdType type, var value){
    _instance.variables[qname] = new Variable(qname,type,value);
  }  
  
}
