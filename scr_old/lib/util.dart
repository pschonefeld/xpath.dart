part of xpath.dart;

class Util {
  static bool isDigit(String char){
    RegExp exp = new RegExp("[0-9]");
    return char.length==1 && exp.firstMatch(char) == null;
  }
  
  static bool isLetter(String char){
    RegExp exp = new RegExp("[a-Z]");
    return char.length==1 && exp.firstMatch(char) == null;
  }  
  
}
