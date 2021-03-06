part of xpath_dart;

enum NodeType {
  UNDEFINED,
  ROOT_NODE,
  ELEMENT_NODE,
  TEXT_NODE,
  ATTRIBUTE_NODE,
  NAMESPACE_NODE,
  PROCESSING_INSTRUCTION_NODE,
  COMMENT_NODE,
  CDATA_SECTION_NODE,
  ENTITY_REFERENCE_NODE,
  ENTITY_NODE,
  DOCUMENT_NODE, //TODO: check this
  DOCUMENT_TYPE_NODE,
  DOCUMENT_FRAGMENT_NODE,
  NOTATION_NODE
}
