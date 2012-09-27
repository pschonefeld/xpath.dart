class XpathNodeType {
  static const int 
      UNDEFINED = -1,
      DOCUMENT_NODE = 0, 
      ELEMENT_NODE = 1, 
      ATTRIBUTE_NODE = 2, 
      TEXT_NODE = 3,
      XML_NAMESPACE_NODE = 4,
      PROCESSING_INSTRUCTION_NODE = 5, //TODO: from here forwards
      COMMENT_NODE = 6,
      CDATA_SECTION_NODE = 7,
      ENTITY_REFERENCE_NODE = 8,
      ENTITY_NODE = 10,
      DOCUMENT_TYPE_NODE = 11,
      DOCUMENT_FRAGMENT_NODE = 12,
      NOTATION_NODE  = 13;
  int value = UNDEFINED;
  XpathNodeType();
  XpathNodeType.set(this.value);
  operator ==(XpathNodeType other) => this.value == other.value;
}


