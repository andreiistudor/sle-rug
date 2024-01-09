module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question1(str text, AId identifier, AType qType)
  | question2(str text, AId identifier, AType qType, AExpr defaultValue)
  | ifQuestion(AExpr condition, list[AQuestion] questions)
  | ifElseQuestion(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = logicalOr(AExpr left, AExpr right) // operator is "||"
  | logicalAnd(AExpr left, AExpr right) // operator is "&&"
  | equality(AExpr left, str operator, AExpr right) // operator is "==" or "!="
  | relational(AExpr left, str operator, AExpr right) // operator is "<", ">", "<=", ">="
  | additive(AExpr left, str operator, AExpr right) // operator is "+" or "-"
  | multiplicative(AExpr left, str operator, AExpr right) // operator is "*" or "/"
  | unary(str operator, AExpr expr) // operator is "!"
  | ref(AId id) // For identifier references
  | literalInt() // For integer literals
  | literalBool() // For boolean literals
  | parenExpr(AExpr expr) // For parenthesized expressions
  ;

data AId(loc src = |tmp:///|)
  = id(str name)
  ;

data AType(loc src = |tmp:///|)
  = typeInteger()
  | typeBoolean()
  | typeString()
  ;
