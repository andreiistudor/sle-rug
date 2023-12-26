module AST

import String;
import IO;

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
  // = question(str name, AIdent identifier, AType type)
  // | question(str name, AIdent identifier, AType type, AExpr expr)
  // | question(AExpr ifBlock, list[AQuestion] thenBlock)
  // | question(AExpr ifBlock, list[AQuestion] thenBlock, list[AQuestion] elseBlock)
  ; 

data AExpr 
  = ref(AId id, loc src)
  // | integer(int value, loc src)
  | add(AExpr left, AExpr right, loc src)
  | sub(AExpr left, AExpr right, loc src)
  | mul(AExpr left, AExpr right, loc src)
  | div(AExpr left, AExpr right, loc src)
  | not(AExpr expr, loc src)
  | and(AExpr left, AExpr right, loc src)
  | orr(AExpr left, AExpr right, loc src)
  | eq(AExpr left, AExpr right, loc src)
  | neq(AExpr left, AExpr right, loc src)
  | gtn(AExpr left, AExpr right, loc src)
  | ltn(AExpr left, AExpr right, loc src)
  | geq(AExpr left, AExpr right, loc src)
  | leq(AExpr left, AExpr right, loc src)
  ;


data AId(loc src = |tmp:///|)
  = id(str name)
  ;

data AType(loc src = |tmp:///|)
  = atype(str name)
  ;