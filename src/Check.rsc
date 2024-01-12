module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenv = {};

  visit(f) {
    case question(str text, AId identifier, AType qType):
      tenv += { <identifier.src, identifier.name, text, typeOfByName(qType.name)> };
    case question(str text, AId identifier, AType qType, _):
      tenv += { <identifier.src, identifier.name, text, typeOfByName(qType.name)> };
  }

  return tenv;
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  visit(f) {
    case form(_, list[AQuestion] questions): 
    {
      for(AQuestion q <- questions) {
        msgs += check(q, tenv, useDef); // Check each question in the form
      }
    }
  }

  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  set[str] encounteredLabels = {};

  switch(q) {
    case question(str label_q, AId id, AType qType):
    {
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      // Check for duplicate labels
      if (label_q in encounteredLabels) {
        msgs += { warning("Duplicate labels detected", id.src) };
      } else {
        encounteredLabels += label_q;
      }
    }
    case question(str label_q, AId id, AType qType, AExpr expr):
    {
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      // Check for duplicate labels
      if (label_q in encounteredLabels) {
        msgs += { warning("Duplicate labels detected", id.src) };
      } else {
        encounteredLabels += label_q;
      }

      Type myExprtype = typeOf(expr, tenv, useDef);
      if(myExprtype != typeOfByName(qType.name))
        msgs += { error("Declared type computed questions should match the type of the expression", id.src) };

      check(expr, tenv, useDef); // Check the expression
    }
    case question(AExpr expr, list[AQuestion] ifQuestions):
    {
      check(expr, tenv, useDef); // Check the expression
      for(AQuestion q <- ifQuestions) {
        msgs += check(q, tenv, useDef); // Check each question in the if statement list
      }
    }
    case question(AExpr expr, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      check(expr, tenv, useDef); // Check the expression
      for(AQuestion q <- ifQuestions) {
        msgs += check(q, tenv, useDef); // Check each question in the if questions list
      }
      for(AQuestion q <- elseQuestions) {
        msgs += check(q, tenv, useDef); // Check each question in the else questions list
      }
    }
  }

  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case ref(bool boolean):
      // Do nothing here
      boolean;
    case ref(int integer):
      // Do nothing here
      integer;
    case ref(AExpr left, AExpr right):
    {
      // Check operand compatibility for binary expressions
      Type leftType = typeOf(left, tenv, useDef);
      Type rightType = typeOf(right, tenv, useDef);

      // Check that both operands are of type integer
      if (leftType != tint() || rightType != tint()) {
        msgs += { error("Incompatible types for operation", e.src) };
      }
    }
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case ref(bool _):
      return tbool();
    case ref(int _):
      return tint();
    case ref(AExpr left, AExpr right):
    {
      // Check operand compatibility for binary expressions
      Type leftType = typeOf(left, tenv, useDef);
      Type rightType = typeOf(right, tenv, useDef);

      // Check that both operands are of type integer
      if ((leftType == tint() && rightType != tint()) || (leftType != tint() && rightType == tint())) {
        return tunknown();
      }
      else {
        return tint();
      }

      // Check that both operands are of type boolean
      if ((leftType == tbool() && rightType != tbool()) || (leftType != tbool() && rightType == tbool())) {
        return tunknown();
      }
      else {
        return tbool();
      }
    }
    case ref(AExpr expr):
    {
      Type exprType = typeOf(expr, tenv, useDef);
      if (exprType == tbool()) {
        return tbool();
      } else if (exprType == tint()) {
        return tint();
      } else {
        return tunknown();
      }

    }
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
Type typeOfByName(str qType) {
  switch(qType) {
    case "integer":
      return tint();
    case "boolean":
      return tbool();
    case "str":
      return tstr();
    
    default:
      return tunknown();
  }
} 

