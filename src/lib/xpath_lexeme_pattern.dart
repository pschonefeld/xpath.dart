
class XpathLexemePattern {
  List<int> pattern = [];
  List<XpathPatternContextPair> tokens = [];
  XpathLexemePattern(List<int> list){
    for(int i in list){
      pattern.add(i);      
    }
  }
}
