module CST2AST

import Syntax;
import AST;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  list[AQuestion] questions = [ cst2ast(q) | q <- f.questions ];
  return form("", [ ], src=f.src); 
}

default AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str text> <Id id> : <Type qType>`:
      return question1(toString(text), id(toString(id), src=id.src), cst2ast(qType), src=q.src);    
    case (Question)`<Str text> <Id id> : <Type qType> = <Expr qExpr>`:
      return question2(toString(text), id(toString(id), src=id.src), cst2ast(qType), cst2ast(qExpr), src=q.src);

    default:
      throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  switch (t) {
    case (Type)`integer`:
      return typeInteger(src=t.src);
    case (Type)`boolean`:
      return typeBoolean(src=t.src);
    case (Type)`string`:
      return typeString(src=t.src);

    default: 
      throw "Unhandled type: <t>";
  }
}