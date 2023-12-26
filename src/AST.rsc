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
  = question(str name, AIdent identifier, AType type)
  | question(str name, AIdent identifier, AType type, AExpr expr)
  | question(AExpr ifBlock, list[AQuestion] thenBlock)
  | question(AExpr ifBlock, list[AQuestion] thenBlock, list[AQuestion] elseBlock)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | ref(int val)
  | ref(AExpr left, AExpr right)
  | ref(AExpr right)
;

data AId(loc src = |tmp:///|)
  = id(str name)
  ;

data AType(loc src = |tmp:///|)
  = atype(str name)
  ;