part of xpath_dart;

class Node extends Item {
  int documentOrder = 0;
  Node ownerDocument;
  Node parent;
  NodeType nodeType = NodeType.ELEMENT_NODE;
  String xmlBase = "";
  String qName = "";
  String namespace = "";
  List<Node> attributes = new List<Node>();
  List<Node> children = new List<Node>();  
  Sequence typedValue = new Sequence();

  Node(value, NodeType type,
      this.documentOrder, this.ownerDocument, this.xmlBase, 
      this.nodeType, this.qName, this.parent) : super(value, type);
  
  Node.defaultItem() : super.defaultItem();
  
  operator ==(Item other) {
    bool result = false;
    if(other.isNode()){ 
      Node node = other;
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
  
  Node getChildAt(int position) => this.children[position];
  Node getAttributeAt(int position) => this.attributes[position];
  bool hasChildNodes() => this.children.length > 0;
  bool hasAttributes() => this.attributes.length > 0;
  
  //return the child nodes of all descendant items in a sequence  
  Sequence getDescendants(){
    Sequence result = new Sequence();
    for(Node node in this.children){
      result.items.add(node);
      result.items.addAll(node.getDescendants().items);
    }
    return result;    
  }
  
  // set child instance at postion
  void setChildAt(int postion, Node node){
    this.children.insert(postion,node);      
  }
  
  // set attribute at postion 
  void setAttributeAt(int position, Node attr){
    this.attributes.insert(position,attr);
  }  
  
  void setNSNode(){;} //TODO:
  
  String toString(){
    String result = "";
    switch(this.nodeType){
      case NodeType.ELEMENT_NODE:
        result = this.qName;
        break;
      case NodeType.ATTRIBUTE_NODE:
        result = "@${this.qName}";
        break;
      case NodeType.DOCUMENT_NODE:
        result = this.qName;
        break;
      case NodeType.TEXT_NODE:
        result = "\"${this.value}\"";
        break;
      default:
        result = this.toString();
        break;
    }
    return result;   
  }
  
}
