part of xpath_dart;

class FunctionArity {
  List<XsdType> arguments = [];
  FunctionArity();
  
  //TODO: can do better
  operator ==(FunctionArity other){
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
