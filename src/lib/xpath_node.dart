/* 
xpath4dart is a dart implementation of XPath 2.0 
Author: Peter Schonefeld (peter dot schonefeld at gmail)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
part of xpath.dart;

class XpathNode extends XpathItem {
  int documentOrder = 0;
  XpathNode ownerDocument;
  XpathNode parent;
  XpathNodeType nodeType = new XpathNodeType.set(XpathNodeType.ELEMENT_NODE);
  String xmlBase = "";
  String qName = "";
  String namespace = "";
  List<XpathNode> attributes = new List<XpathNode>();
  List<XpathNode> children = new List<XpathNode>();  
  XpathSequence typedValue = new XpathSequence();

  XpathNode(String value, String xsdType, 
      this.documentOrder, this.ownerDocument, this.xmlBase, 
      this.nodeType, this.qName, this.parent) : super(value, xsdType);
  
  XpathNode.defaultItem() : super.defaultItem();
  
  operator ==(XpathItem other) {
    bool result = false;
    if(other.isNode()){ 
      XpathNode node = other;
      String s1 = this.ownerDocument.toString();
      String s2 = node.ownerDocument.toString();
      if((s1.compareTo(s2) == 0) && (this.documentOrder==node.documentOrder)){
        result = true;
      }
    }
    return result;      
  }
  
  bool isNode() => true;
  
  String getLocalName(){ 
    String result = "";
    int separateAt = this.qName.indexOf(':');
    if(separateAt>-1){ 
      result = this.qName.substring(separateAt+1);
    }
    else{
      result = this.qName;
    }
    return result;
  }
  
  // returns Expanded-QName (ns URI:LocalName)  
  // the Expanded-QName is (Namespace URI":")?LocalName of a node
  // TODO: must implement namespaces  
  String getExpandedQName() => this.qName;
  
  XpathNode getChildAt(int position) => this.children[position];
  XpathNode getAttributeAt(int position) => this.attributes[position];
  bool hasChildNodes() => this.children.length > 0;
  bool hasAttributes() => this.attributes.length > 0;
  
  //return the child nodes of all descendant items in a sequence  
  XpathSequence getDescendants(){
    XpathSequence result = new XpathSequence();
    for(XpathNode node in this.children){
      result.items.add(node);
      result.items.addAll(node.getDescendants().items);
    }
    return result;    
  }
  
  // set child instance at postion
  void setChildAt(int postion, XpathNode node){
    this.children.insert(postion,node);      
  }
  
  // set attribute at postion 
  void setAttributeAt(int position, XpathNode attr){
    this.attributes.insert(position,attr);
  }  
  
  void setNSNode(){;} //TODO:
  
  String toString(){
    String result = "";
    switch(this.nodeType.value){
      case XpathNodeType.ELEMENT_NODE:
        result = this.qName;
        break;
      case XpathNodeType.ATTRIBUTE_NODE:
        result = "@${this.qName}";
        break;
      case XpathNodeType.DOCUMENT_NODE:
        result = this.qName;
        break;
      case XpathNodeType.TEXT_NODE:
        result = "\"${this.value}\"";
        break;
    }
    return result;   
  }
  
}
