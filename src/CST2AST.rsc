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
  return form(cst2ast(f.name), questions, src=f.src);
}

default AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str text> <Id identifier> : <Type qType>`:
      return question1(cst2ast(text), cst2ast(identifier), cst2ast(qType), src=q.src);    
    case (Question)`<Str text> <Id identifier> : <Type qType> = <Expr qExpr>`:
      return question2(cst2ast(text), cst2ast(identifier), cst2ast(qType), cst2ast(qExpr), src=q.src);
    case (Question)`if (<Expr condition>) { <Question* questions> }`:
      return ifQuestion(cst2ast(condition), [ cst2ast(q) | q <- questions ], src=q.src);
    case (Question)`if (<Expr condition>) { <Question* questions> } else { <Question* elseQuestions> }`:
      return ifElseQuestion(cst2ast(condition), [ cst2ast(q) | q <- questions ], [ cst2ast(q) | q <- elseQuestions ], src=q.src);

    default:
      throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    // case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);

    case (Expr)`<Expr left> || <Expr right>`:
      return logicalOr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> && <Expr right>`:
      return logicalAnd(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> == <Expr right>`:
      return equality(cst2ast(left), "==" ,cst2ast(right), src=e.src);
    case (Expr)`<Expr left> != <Expr right>`:
      return equality(cst2ast(left), "!=", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> + <Expr right>`:
      return additive(cst2ast(left), "+", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> - <Expr right>`:
      return additive(cst2ast(left), "-", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> * <Expr right>`:
      return multiplicative(cst2ast(left), "*", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> / <Expr right>`:
      return multiplicative(cst2ast(left), "/", cst2ast(right), src=e.src);
    case (Expr)`!<Expr expr>`:
      return unary("!", cst2ast(expr), src=e.src);
    // case (Expr)`<Id id>`:
    //   return ref(cst2ast(id), src=e.src);
    // case (Expr)`<Int i>`:
    //   return literalInt();
    // case (Expr)`<Bool b>`:
    //   return literalBool();
    case (Expr)`(<Expr expr>)`:
      return parenExpr(cst2ast(expr), src=e.src);

    default: throw "Unhandled expression: <e>";
  }
}

default AId cst2ast(Id i) {
  return id("<i>", src=i.src);
}

default str cst2ast(Str s) {
  return "<s>";
}

default str cst2ast(Id s) {
  return "<s>";
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
