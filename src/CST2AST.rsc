module CST2AST

import IO;
import String;
import Syntax;
import AST;

import ParseTree;

AForm cst2ast(start[Form] sf) {
  Form f = sf.top;
  list[AQuestion] questions = [cst2ast(q) | q <- f.questions];
  return form(f.name, questions, src=f.src);
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str s> <Identifier id> [:] <Type t> ([=] <Expr e>)?`:
      return question(s, cst2ast(id), cst2ast(t), e ? just(cst2ast(e)) : nothing(), src=q.src);
    case (Question)`If [(] <Expr e> [)] { <Question* qs_left> } (Else { <Question* qs_right> })?`:
      return ifQuestion(cst2ast(e), [cst2ast(q) | q <- qs_left], qs_right ? just([cst2ast(q) | q <- qs_right]) : nothing(), src=q.src);
    default:
      throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case identifier(x): 
      return ref(id(x, src=e.src), src=e.src);
    case integer(n): 
      return integer(n, src=e.src);
    case mul(x, y): 
      return mul(cst2ast(x), cst2ast(y), src=e.src);
    case div(x, y): 
      return div(cst2ast(x), cst2ast(y), src=e.src);
    case add(x, y): 
      return add(cst2ast(x), cst2ast(y), src=e.src);
    case sub(x, y): 
      return sub(cst2ast(x), cst2ast(y), src=e.src);
    case not(x): 
      return not(cst2ast(x), src=e.src);
    case and(x, y): 
      return and(cst2ast(x), cst2ast(y), src=e.src);
    case orr(x, y): 
      return orr(cst2ast(x), cst2ast(y), src=e.src);
    case eq(x, y): 
      return eq(cst2ast(x), cst2ast(y), src=e.src);
    case neq(x, y): 
      return neq(cst2ast(x), cst2ast(y), src=e.src);
    case gtn(x, y): 
      return gtn(cst2ast(x), cst2ast(y), src=e.src);
    case ltn(x, y): 
      return ltn(cst2ast(x), cst2ast(y), src=e.src);
    case geq(x, y): 
      return geq(cst2ast(x), cst2ast(y), src=e.src);
    case leq(x, y): 
      return leq(cst2ast(x), cst2ast(y), src=e.src);
    case parens(x): 
      return cst2ast(x);
    default:
      throw "Unhandled expression: <e>";
  }
}


AType cst2ast(Type t) {
  switch (t) {
    case (Type)`bool`: 
      return atype(src=t.src);
    case (Type)`int`: 
      return atype(src=t.src);
    case (Type)`str`: 
      return atype(src=t.src);
    default:
      throw "Unhandled type: <t>";
  }
}
