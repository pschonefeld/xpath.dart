
class XpathFunctionArity {
  List<XsdType> arguments = [];
  XpathFunctionArity();
  
  //TODO: refine
  operator ==(XpathFunctionArity other){
    bool result = true;
    if(this.arguments.length != other.arguments.length) return false;
    for(int i = 0; i < this.arguments.length; i++){
      if(this.arguments[i]!=other.arguments[i]){
        result = false;
        break;
      }
    }
    return result;  
  }

}
