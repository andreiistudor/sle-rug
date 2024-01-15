module Syntax

extend lang::std::Layout;

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question
  = Str question Id identifier ":" Type qType
  | Str question Id identifier ":" Type qType "=" Expr defaultValue
  | "if" "(" Expr condition ")" "{" Question* questions "}"
  | "if" "(" Expr condition ")" "{" Question* questions "}" "else" "{" Question* questions "}"
  ;

syntax Expr
  = Id                           // Identifier
  | Int                          // Integer literal
  | Bool                         // Boolean literal
  | "(" Expr ")"                 // Parenthesized expression
  > left Expr ("*" | "/") Expr   // Multiplicative, left associative
  > left Expr ("+" | "-") Expr   // Additive, left associative
  > right "!" Expr               // Unary NOT, right associative
  > left Expr "&&" Expr          // Logical AND, left associative
  > left Expr "||" Expr          // Logical OR, left associative
  > non-assoc Expr ("\<" | "\>" | "\<=" | "\>=") Expr  // Relational, non-associative
  > non-assoc Expr ("==" | "!=") Expr  // Equality, non-associative
  ;

syntax Type
  = "integer"                     // Integer type
  | "boolean"                     // Boolean type
  | "string"                      // String type
  ;

lexical Bool = "true" | "false";  // Boolean lexical
lexical Str = "\"" ![\"]* "\"";   // String lexical
lexical Int = [\-]?[0-9]+;        // Integer lexical
lexical Id = ([a-z A-Z][a-z A-Z 0-9 _]*) \ "true" \ "false"; // Identifier lexical