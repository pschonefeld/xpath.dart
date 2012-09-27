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
class XpathItem {
  
  var value = "";
  var xsdType = ""; //TODO: will eventually point to instance of XsdType (xs:anySimpleType?) as default
  XpathNodeType nodeType = new XpathNodeType();
  var domObject; //TODO: map to orinal input node 
  
  XpathItem(this.value, this.xsdType);
  XpathItem.defaultItem();

  //TODO: 
  operator ==(XpathItem other) => false;
  
  //TODO:
  int getDocumentOrder(){
    return -1;
  }

  //TODO:
  bool isNode(){
    return false; 
  }
  
  String toString(){
    return this.value;
  }
  
}
