
class XpathFunctionSignature {
  String namespace = ""; //TODO: this should point to an inscope ns
  String localName = ""; 
  XsdType returnType;
  XpathFunctionArity arity;
  
  XpathFunctionSignature(this.namespace,this.localName, this.returnType, this.arity);
  
  operator ==(XpathFunctionSignature other){
    bool result = true;
    if(this.namespace != other.namespace){
      result = false;
    }
    else if(this.localName != other.localName){
      result = false;
    }    
    else if(this.returnType != other.returnType){
      result = false;      
    }
    else if(this.arity != other.arity){
      result = false;
    }
    return result;
  }
  
}
