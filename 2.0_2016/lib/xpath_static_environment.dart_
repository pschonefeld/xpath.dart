
class XpathStaticEnvironment {
  //NB:See all variable info in dynamic environment
  static XpathStaticEnvironment _instance;
  Map<String, XsdType> types = {}; //all types available to the expression
  Map<String, XpathFunctionSignature> _functions = {}; //available functions (allows overloading)
  
  factory XpathStaticEnvironment() {
    if (_instance == null) {
      _instance = new XpathStaticEnvironment();
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
  
  void initFunctions(){ //TODO: this is from my first version of this lib in c++ left in for ref - ps
    //XSDType item = ((KeyTypePair)this.Types.get(7)).Type; //TODO: make map 
    //XSDType node = ((KeyTypePair)this.Types.get(8)).Type;
    //XSDType integer = ((KeyTypePair)this.Types.get(3)).Type;
   /*
    ** function -- fn:root
    this.Functions["root"] = new XPathFuncSigs();
    map<string,XPathFuncSigs*>::iterator it = this->Functions.find("root");
    fn:root() as node
    it->second->Signatures.push_back(new XPathFunction("fn","root",ptNode));
    fn:root($srcval as node) as node
    it->second->Signatures.push_back(new XPathFunction("fn","root",ptNode));
    it->second->Signatures.back()->Arity.push_back(ptNode);

    **function -- fn:position
    XPathFuncSigs *pFunc = this->Functions["position"] = new XPathFuncSigs();
    map<string,XPathFuncSigs*>::iterator it = this->Functions.find("position");
    fn:position() as unsignedInt?
    pFunc->Signatures.push_back(new XPathFunction("fn","position",ptInt));
    pFunc->Signatures.back()->PFunc = &CEvalEngine::FuncPosition;
   */
  }

  XpathFunction getFunction(String ns, String name, XpathFunctionArity arity){
    /* TODO:
    //find the set of functions matching the local name.
    map<string,XPathFuncSigs*>::iterator it = this->Functions.find(name);
    //if found iterate thru the function signatures until a match is found and return
    if(it!=this->Functions.end()){  
      vector<XPathFunction*>::iterator jt = it->second->Signatures.begin();
      for(jt;jt!=it->second->Signatures.end();jt++){
        if((*jt)->Namespace==ns){
          if( ((int) (*jt)->Arity.size()==0 && !arity) || 
            ((*jt)->Arity == (*arity)) )
            return (*jt);
        }
      }
    }
    */
    return null;
  }
}
