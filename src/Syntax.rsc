module Syntax

extend lang::std::Layout;
extend lang::std::Id;

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question
  = Str question Id identifier ":" Type qType
  | Str question Id identifier ":" Type qType "=" Expr defaultValue
  | "if" "(" Expr condition ")" "{" Question* questions "}"
  ;

syntax Expr 
  = LogicalExpr;

syntax LogicalExpr
  = LogicalExpr lhs "||" EqExpr rhs
  > EqExpr;

syntax EqExpr
  = EqExpr lhs "==" RelExpr rhs
  | EqExpr lhs "!=" RelExpr rhs
  > RelExpr;

syntax RelExpr
  = RelExpr lhs "\>" AddExpr rhs
  | RelExpr lhs "\<" AddExpr rhs
  | RelExpr lhs "\>=" AddExpr rhs
  | RelExpr lhs "\<=" AddExpr rhs
  | RelExpr lhs "&&" AddExpr rhs
  > AddExpr;

syntax AddExpr
  = AddExpr lhs "+" MulExpr rhs
  | AddExpr lhs "-" MulExpr rhs
  > MulExpr;

syntax MulExpr
  = MulExpr lhs "*" UnaryExpr rhs
  | MulExpr lhs "/" UnaryExpr rhs
  > UnaryExpr;

syntax UnaryExpr
  = "!" UnaryExpr
  | PrimaryExpr;

syntax PrimaryExpr
  = Id
  | "true"
  | "false"
  | "(" Expr ")";


syntax Type
  = "integer"
  | "boolean"
  | "string"
  ;

lexical Str = "\"" ![\"]* "\""; 
lexical Int = [0-9]+; 
lexical Bool = "true" | "false"; 
