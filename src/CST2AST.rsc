module CST2AST

import Syntax;
import AST;
import String;
import IO;

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
  return form("<f.name>", questions, src=f.src);
}

default AQuestion cst2ast(Question q) {
  switch (q) {  
    case (Question)`"<Str text>" <Id identifier> : <Type qType>`:
      return question("<text>", id("<identifier>", src=identifier.src), cst2ast(qType), src=q.src);    
    case (Question)`"<Str text>" <Id identifier> : <Type qType> = <Expr qExpr>`:
      return question("<text>", id("<identifier>", src=identifier.src), cst2ast(qType), cst2ast(qExpr), src=q.src);
    case (Question)`if (<Expr condition>) { <Question* questions> }`:
      return question(cst2ast(condition), [ cst2ast(qs) | Question qs <- questions ], src=q.src);
    case (Question)`if (<Expr condition>) { <Question* questions> } else { <Question* elseQuestions> }`:
      return question(cst2ast(condition), [ cst2ast(qs) | Question qs <- questions ], [ cst2ast(qs) | Question qs <- elseQuestions ], src=q.src);

    default:
      throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Expr left> || <Expr right>`:
      return ref(cst2ast(left), "||", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> && <Expr right>`:
      return ref(cst2ast(left), "&&", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> == <Expr right>`:
      return ref(cst2ast(left), "==", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> != <Expr right>`:
      return ref(cst2ast(left), "!=", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \< <Expr right>`:
      return ref(cst2ast(left), "\<", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \> <Expr right>`:
      return ref(cst2ast(left), "\>", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \<= <Expr right>`:
      return ref(cst2ast(left), "\<=", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \>= <Expr right>`:
      return ref(cst2ast(left), "\>=", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> + <Expr right>`:
      return ref(cst2ast(left), "+", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> - <Expr right>`:
      return ref(cst2ast(left), "-", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> * <Expr right>`:
      return ref(cst2ast(left), "*", cst2ast(right), src=e.src);
    case (Expr)`<Expr left> / <Expr right>`:
      return ref(cst2ast(left), "/", cst2ast(right), src=e.src);
    case (Expr)`!<Expr expr>`:
      return ref(cst2ast(expr), true, src=e.src);
    case (Expr)`<Identifier identifier>`:
      return ref(id("<identifier>", src=identifier.src), src=e.src);
    case (Expr)`<Int i>`:
      return ref(toInt("<i>"), src=i.src);
    case (Expr)`<Bool b>`:
      return ref(toBool("<b>"), src=b.src);
    case (Expr)`"<Str s>"`:
      return ref("<s>", src=s.src);
    case (Expr)`(<Expr expr>)`:
      return ref(cst2ast(expr), false, src=e.src);

    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  return setType("<t>", src=t.src); // 
}

bool toBool(str s) {
  switch (s) {
    case "true": return true;
    case "false": return false;
    default: throw "Not a boolean: <s>";
  }
}
