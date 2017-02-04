part of xpath_dart;

class Item {
  var _value;
  NodeType _nodeType;
  var _xsdType = "xs:anySimpleType"; //TODO: will eventually point to instance of XsdType (xs:anySimpleType as default?)
  var domObject; //TODO: map to source input Element (not part of spec)

  dynamic get value => _value;
  NodeType get nodeType => _nodeType;
  String get xsdType => _xsdType;

  bool isNode () => true;

  Item(this._value,this._nodeType){ _xsdType = "xs:anySimpleType";}
  Item.defaultItem();

  //TODO:
  int getDocumentOrder(){
    return -1;
  }

}