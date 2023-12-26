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
    case (Expr)`<Identifier x>`: 
      return ref(id(x, src=e.src), src=e.src);
    case (Expr)`<Int n>`: 
      return ref(n, src=e.src);
    case (Expr)`<Expr x> "*" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "/" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "+" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "-" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`"!" <Expr x>`: 
      return ref(cst2ast(x), src=e.src);
    case (Expr)`<Expr x> "&&" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "||" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "==" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "!=" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "\>" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "\<" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "\>=" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`<Expr x> "\<=" <Expr y>`: 
      return ref(cst2ast(x), cst2ast(y), src=e.src);
    case (Expr)`("(" <Expr x> ")")`: 
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
