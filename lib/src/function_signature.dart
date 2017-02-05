part of xpath_dart;

class FunctionSignature {
  String namespace = ""; //TODO: this should point to an inscope ns
  String localName = ""; 
  XsdType returnType;
  FunctionArity arity;
  
  FunctionSignature(this.namespace,this.localName, this.returnType, this.arity);
  
  operator ==(FunctionSignature other){
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
