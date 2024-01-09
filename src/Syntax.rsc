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

syntax Expr
  = left Expr "||" Expr          // Logical OR, left associative
  > left Expr "&&" Expr          // Logical AND, left associative
  > non-assoc Expr ("==" | "!=") Expr  // Equality, non-associative
  > non-assoc Expr ("\<" | "\>" | "\<=" | "\>=") Expr  // Relational, non-associative
  > left Expr ("+" | "-") Expr   // Additive, left associative
  > left Expr ("*" | "/") Expr   // Multiplicative, left associative
  > right "!" Expr               // Unary NOT, right associative
  > Id                           // Identifier
  > Int                          // Integer literal
  > Bool                         // Boolean literal
  > "(" Expr ")"                 // Parenthesized expression
  ;

syntax Type
  = "integer"
  | "boolean"
  | "string"
  ;

lexical Str = "\"" ![\"]* "\""; 
lexical Int = [0-9]+; 
lexical Bool = "true" | "false"; 
