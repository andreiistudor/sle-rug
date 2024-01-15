module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions) // For forms with questions
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str text, AId identifier, AType qType) // For questions without default values
  | question(str text, AId identifier, AType qType, AExpr defaultValue) // For questions with default values
  | question(AExpr condition, list[AQuestion] questions) // For questions with conditions
  | question(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions) // For questions with if-else conditions
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id) // For identifier references
  | ref(bool boolean) // For boolean literals
  | ref(int number) // For integer literals
  | ref(str string) // For string literals
  | ref(AExpr left, str operation, AExpr right) // Binary expressions
  | ref(AExpr expr, bool negated) // Unary expression
  ;

data AId(loc src = |tmp:///|)
  = id(str name) // For identifier names
  ;

data AType(loc src = |tmp:///|)
  = setType(str name) // Setting the type
  ;
