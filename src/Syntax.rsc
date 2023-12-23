module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question 
  = regular: "question" Id ":" Type 
  | computed: "question" Id ":" Type "=" Expr 
  | block: "{" Question* "}" 
  | conditional: "if" "(" Expr ")" Question ("else" Question)?;

syntax Expr 
  = ExprOr
  ;

syntax ExprOr 
  = ExprOr "||" ExprAnd 
  > ExprAnd
  ;

syntax ExprAnd 
  = ExprAnd "&&" ExprEq 
  > ExprEq
  ;

syntax ExprEq 
  = ExprEq ("==" | "!=") ExprRel
  > ExprRel
  ;

syntax ExprRel
  = ExprRel ("\<" | "\>" | "\<=" | "\>=") ExprAdd
  > ExprAdd
  ;

syntax ExprAdd 
  = ExprAdd ("+" | "-") ExprMul 
  > ExprMul 
  ;

syntax ExprMul 
  = ExprMul ("*" | "/") ExprUnary 
  > ExprUnary
  ;

syntax ExprUnary 
  = "!" ExprUnary
  | ExprPrimary
  ;

syntax ExprPrimary 
  = Int | Bool | Str 
  | Id 
  | "(" Expr ")"
  ;

syntax Type 
  = "bool" 
  | "int" 
  | "str";

lexical Str 
  =  [\"][a-zA-Z_\ :0-9?]*[\"]; 

lexical Int 
  = [0-9]+ ;

lexical Bool 
  = "true" | "false";
