part of xpath_dart;

class StaticEnvironment {
  //NB:See all variable info in dynamic environment
  static StaticEnvironment _instance;
  Map<String, XsdType> types = {}; //all types available to the expression
  Map<String, FunctionSignature> _functions = {}; //available functions (allow overloading)
  
  factory StaticEnvironment() {
    if (_instance == null) {
      _instance = new StaticEnvironment();
      _instance.initTypes();
      _instance.initFunctions();
    }
    return _instance;
  }
  
  void initTypes(){
    this.types["xs:anySimpleType"] = new XsdType("xs","anySimpleType");
    this.types["xs:anyType"] = new XsdType("xs", "anyType");
    this.types["xs:string"] = new XsdType("xs", "string");
    this.types["xs:integer"] = new XsdType("xs", "integer");
    this.types["xs:decimal"] = new XsdType("xs", "decimal");
    this.types["xs:double"] = new XsdType("xs", "double");
    this.types["dm:sequence"] = new XsdType("dm", "sequence");
    this.types["dm:item"] = new XsdType("dm", "item");
    this.types["dm:node"] = new XsdType("dm", "node");    
  }
  
  void initFunctions(){
    //TODO
  }

  Function getFunction(String ns, String name, FunctionArity arity){
    // TODO
     return null;
  }
}
