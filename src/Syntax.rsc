module Syntax

extend lang::std::Layout;
extend lang::std::Id;

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question
  = Str question Id identifier ":" Type qType
  | Str question Id identifier ":" Type qType "=" Expr defaultValue
  | "if" "(" Expr condition ")" "{" Question* questions "}"
  | "if" "(" Expr condition ")" "{" Question* questions "}" "else" "{" Question* questions "}"
  ;

syntax Expr = LogicalExpr;

syntax LogicalExpr
  = LogicalExpr "||" AndExpr
  > AndExpr;

syntax AndExpr
  = AndExpr "&&" EqualityExpr
  > EqualityExpr;

syntax EqualityExpr
  = EqualityExpr "==" RelationalExpr
  | EqualityExpr "!=" RelationalExpr
  > RelationalExpr;

syntax RelationalExpr
  = RelationalExpr "\<" AdditiveExpr
  | RelationalExpr "\>" AdditiveExpr
  | RelationalExpr "\<=" AdditiveExpr
  | RelationalExpr "\>=" AdditiveExpr
  > AdditiveExpr;

syntax AdditiveExpr
  = AdditiveExpr "+" MultiplicativeExpr
  | AdditiveExpr "-" MultiplicativeExpr
  > MultiplicativeExpr;

syntax MultiplicativeExpr
  = MultiplicativeExpr "*" UnaryExpr
  | MultiplicativeExpr "/" UnaryExpr
  > UnaryExpr;

syntax UnaryExpr
  = "!" UnaryExpr
  | PrimaryExpr;

syntax PrimaryExpr
  = Id
  | Int
  | Bool
  | "(" Expr ")"
  ;

syntax Type
  = "integer"
  | "boolean"
  | "string"
  ;

lexical Str = "\"" ![\"]* "\""; 
lexical Int = [0-9]+; 
lexical Bool = "true" | "false"; 
