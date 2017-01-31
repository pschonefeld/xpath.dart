part of xpath_dart;

class XsdType {
  
  String _namespace = "";
  String _localName = "";
  String _definition = "";

  String get namespace => _namespace;
  String get localName => _localName;
  String get definition => _definition;

  XsdType(this._namespace, this._localName);
  
  operator ==(XsdType other){
    return (this._namespace.compareTo(other.namespace)==1 &&
            this._localName.compareTo(other.localName)==1)?true:false;
  }

}
