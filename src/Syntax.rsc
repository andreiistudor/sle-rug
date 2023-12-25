module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

syntax Question 
  = Str string Identifier id_name [:] Type type ([=] Expr expr)?
  | If  [(] Expr expr [)] [{] Question* questions_left [}] (Else "{" Question* questions_right "}")?
  ;

syntax Expr 
  = ident: Identifier
  | Int num
  | [()] Expr expr [)]
  > left (left Expr left Mul Expr right | left Expr left Div Expr right)
  > left (left Expr left Add Expr right | left Expr left Sub Expr right)
  > right Excl Expr right
  > left Expr left And Expr right
  > left Expr left Orr Expr right
  > non-assoc
    (
      non-assoc Expr left Eqq Expr right
    | non-assoc Expr left Neq Expr right
    | non-assoc Expr left Gtn Expr right
    | non-assoc Expr left Ltn Expr right
    | non-assoc Expr left Geq Expr right
    | non-assoc Expr left Leq Expr right
    )
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

lexical Identifier
  = Id \Reserved
  ;

lexical If
  = "if"
  ;

lexical Else
  = "else"
  ;

lexical Mul
  = "*"
  ;

lexical Div
  = "/"
  ;
  
lexical Add
  = "+"
  ;

lexical Sub
  = "-"
  ;

lexical Excl
  = "!"
  ;

lexical And
  = "&&"
  ;

lexical Orr
  = "||"
  ;

lexical Eqq
  = "=="
  ;

lexical Neq
  = "!="
  ;

lexical Gtn
  = "\>"
  ;

lexical Ltn
  = "\<"
  ;

lexical Geq
  = "\>="
  ;

lexical Leq
  = "\<="
  ;

keyword Reserved
  = "if" | "else" | "false" | "true"
  ;