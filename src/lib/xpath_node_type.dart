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


