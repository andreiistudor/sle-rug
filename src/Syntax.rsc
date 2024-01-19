module Syntax

extend lang::std::Layout;
extend lang::std::Id;

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question
  = "\"" Str question "\"" Identifier identifier ":" Type qType
  | "\"" Str question "\"" Identifier identifier ":" Type qType "=" Expr defaultValue
  | "if" "(" Expr condition ")" "{" Question* questions "}"
  | "if" "(" Expr condition ")" "{" Question* questions "}" "else" "{" Question* questions "}"
  ;

syntax Expr
  = Identifier                   // Identifier
  | Int                          // Integer literal
  | Bool                         // Boolean literal
  | "\"" Str "\""                // String literal
  | "(" Expr ")"                 // Parenthesized expression
  > left Expr ("*" | "/") Expr   // Multiplicative, left associative
  > left Expr ("+" | "-") Expr   // Additive, left associative
  > right "!" Expr               // Unary NOT, right associative
  > non-assoc Expr ("\<" | "\>" | "\<=" | "\>=") Expr  // Relational, non-associative
  > non-assoc Expr ("==" | "!=") Expr  // Equality, non-associative
  > left Expr "&&" Expr          // Logical AND, left associative
  > left Expr "||" Expr          // Logical OR, left associative
  ;

syntax Type
  = "integer"                     // Integer type
  | "boolean"                     // Boolean type
  | "string"                      // String type
  ;

keyword Reserved = "form" | "if" | "else" | "true" | "false" | "integer" | "boolean" | "string"; // Reserved keywords
lexical Bool = "true" | "false";  // Boolean lexical
lexical Str = ![\"]*;   // String lexical
lexical Int = [\-]?[0-9]+;        // Integer lexical
lexical Identifier = Id \ Reserved; // Identifier lexical