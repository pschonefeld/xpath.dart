part of xpath_dart;

class Util {

  //TODO: add unicode support (waiting for language implementation)
  static bool isDigit(String char){
    RegExp exp = new RegExp("[0-9]");
    return char.length==1 && exp.firstMatch(char) == null;
  }

  //TODO: add unicode support (waiting for language implementation)
  static bool isLetter(String char){
    RegExp exp = new RegExp("[a-Z]");
    return char.length==1 && exp.firstMatch(char) == null;
  }

}