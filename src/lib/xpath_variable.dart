
class XpathVariable {
  String qName;
  XsdType type;
  var value; //TODO: will be a XPathSequence or XPathItem ... perhaps build some type saefty into a setter 
  XpathVariable(this.qName, this.type, this.value);
}
