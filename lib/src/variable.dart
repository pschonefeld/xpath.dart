part of xpath_dart;

class Variable {
  String qName;
  XsdType type;
  var value; //TODO: will be a XPathSequence or XPathItem ... perhaps build some type saefty into a setter 
  Variable(this.qName, this.type, this.value);
}
