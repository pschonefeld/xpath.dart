part of xpath_dart;

class LexemePattern {
  List<int> pattern = [];
  List<PatternTokenPair> tokens = [];
  LexemePattern(List<int> list){
    for(int i in list){
      pattern.add(i);      
    }
  }
}
