part of xpath.dart;

class XpathLexemePattern {
  List<int> pattern = [];
  List<XpathPatternTokenPair> tokens = [];
  XpathLexemePattern(List<int> list){
    for(int i in list){
      pattern.add(i);      
    }
  }
}
