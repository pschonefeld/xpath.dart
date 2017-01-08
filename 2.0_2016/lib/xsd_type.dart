
class XsdType {
  
  String namespace = "";
  String localName = "";
  String definition = "";

  XsdType(this.namespace, this.localName);
  
  operator ==(XsdType other){
    return (this.namespace.compareTo(other.namespace)==1 && 
            this.localName.compareTo(other.localName)==1)?true:false;   
  }
}
