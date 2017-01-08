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

class XpathSequence {
  
  List<XpathItem> items = new List<XpathItem>();

  XpathSequence GetAtomicValues(){
    XpathSequence result = new XpathSequence();
    for(XpathItem item in this.items){
      if(!item.isNode())result.items.add(item);
    }
    return result;
  } 

  XpathSequence getNodesOfType(XpathNodeType nodeType){
    XpathSequence result = new XpathSequence();
    for(XpathItem item in this.items){
      if(item.isNode() && item.nodeType==nodeType) {
        result.items.add(item);
      }
    }
    return result;   
  } 
  
  void sortItemsByDocOrder(){
    //TODO:
  }
  
  //for debug output
  String toString(){
    String result = "";
    for(XpathItem item in this.items){
      if(item.isNode()){
        result += "<${item.toString()}> , ";  
      }
      else {
        result += "${item.toString()} , ";
      }
    } 
    return result == ""?"nothing":result.substring(0,result.lastIndexOf(','));
  }
  
  //for debug output  
  String toHTMLString(){
    String result = "";
    for(XpathItem item in this.items){
      if(item.isNode()){
        var s = item.toString();
        if(s.contains("\"")){
          result += "$s , ";
        }
        else {
          result += "&lt;$s&gt; , ";
        }
      }
      else {
        result += "${item.toString()} , ";
      }
    } 
    return result == ""?"nothing":result.substring(0,result.lastIndexOf(','));
  }  
  
}
