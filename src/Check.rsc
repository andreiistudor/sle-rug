module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

set[str] encounteredLabels = {};
set[str] encounteredIds = {};

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
  encounteredLabels = {};
  encounteredIds = {};
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

  switch(q) {
    case question(str label_q, AId id, AType qType):
    {
      if (id.name in encounteredIds) {
        msgs += { error("Duplicate question identifiers detected", id.src) };
      } else {
        encounteredIds += id.name;
      }

      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      // Check for duplicate labels
      if (isStringInSet(label_q, encounteredLabels)) {
        msgs += { warning("Duplicate labels detected", id.src) };
      } else {
        encounteredLabels += label_q;
      }
    }
    case question(str label_q, AId id, AType qType, AExpr expr):
    {
      if (id.name in encounteredIds) {
        msgs += { error("Duplicate question identifiers detected", id.src) };
      } else {
        encounteredIds += id.name;
      }

      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      // Check for duplicate labels
      if (isStringInSet(label_q, encounteredLabels)) {
        msgs += { warning("Duplicate labels detected", id.src) };
      } else {
        encounteredLabels += label_q;
      }

      Type myExprtype = typeOf(expr, tenv, useDef);
      if(myExprtype != typeOfByName(qType.name))
      {
        msgs += { error("Declared type computed questions should match the type of the expression", id.src) };
      }

      msgs += check(expr, tenv, useDef, typeOfByName(qType.name)); // Check the expression
    }
    case question(AExpr expr, list[AQuestion] ifQuestions):
    {
      msgs += check(expr, tenv, useDef, tbool()); // Check the expression
      for(AQuestion qs <- ifQuestions) {
        msgs += check(qs, tenv, useDef); // Check each question in the if statement list
      }
    }
    case question(AExpr expr, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      msgs += check(expr, tenv, useDef, tbool()); // Check the expression
      for(AQuestion qs <- ifQuestions) {
        msgs += check(qs, tenv, useDef); // Check each question in the if questions list
      }
      for(AQuestion qs <- elseQuestions) {
        msgs += check(qs, tenv, useDef); // Check each question in the else questions list
      }
    }
  }

  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef, Type returnType) {
  set[Message] msgs = {};

  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case ref(bool boolean):
      if (returnType != typeOfByName("boolean")) {
        msgs += { error("This is not a boolean expression", e.src) };
      }
    case ref(int integer):
      if (returnType != typeOfByName("integer")) {
        msgs += { error("This is not an integer expression", e.src) };
      }
    case ref(str string):
      if (returnType != typeOfByName("string")) {
        msgs += { error("This is not a string expression", e.src) };
      }
    case ref(AExpr left, str operation, AExpr right):
    {
      Type exprType = typeOf(e, tenv, useDef);
      if (exprType != returnType) {
        msgs += { error("Incorrect type for expression", e.src) };
      }
      // Check operand compatibility for binary expressions
      Type leftType = typeOf(left, tenv, useDef);
      Type rightType = typeOf(right, tenv, useDef);

      // Check operation compatibility for binary expressions
      if (operation == "+") {
        if (leftType != tstr() && leftType != tint()) {
          msgs += { error("Incompatible types for operation", e.src) };
        }
        if (rightType != tstr() && rightType != tint()) {
          msgs += { error("Incompatible types for operation", e.src) };
        }
      } else if (operation == "-" || operation == "*" || operation == "/" || operation == "\<" || operation == "\>" || operation == "\<=" || operation == "\>=") {
        if (leftType != tint() || rightType != tint()) {
          msgs += { error("Incompatible types for operation", e.src) };
        }
      } else if (operation == "&&" || operation == "||") {
        if (leftType != tbool() || rightType != tbool()) {
          msgs += { error("Incompatible types for operation", e.src) };
        }
      } else if (leftType != rightType) {
        msgs += { error("Incompatible types for operation", e.src) };
      }
    }
    case ref(AExpr expr, bool negated):
    {
      Type exprType = typeOf(expr, tenv, useDef);
      if (negated) {
        if (exprType != typeOfByName("boolean")) {
          msgs += { error("This is not a boolean expression", e.src) };
        }
      } else {
        if (exprType != returnType) {
          msgs += { error("Incorrect type for expression", e.src) };
      }
      }
    }
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):
    {
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    }
    case ref(bool _):
      return tbool();
    case ref(int _):
      return tint();
    case ref(str _):
      return tstr();
    case ref(AExpr left, str operation, AExpr right):
    {
      // Check operand compatibility for binary expressions
      Type leftType = typeOf(left, tenv, useDef);
      Type rightType = typeOf(right, tenv, useDef);

      // Check operation compatibility for binary expressions
      if (operation == "+") {
        if (leftType == tstr()) {
          if (rightType == tstr()) {
            return tstr();
          } else if (rightType == tint()) {
            return tstr();
          } else {
            return tunknown();
          }
        } else if (leftType == tint()) {
          if (rightType == tstr()) {
            return tstr();
          } else if (rightType == tint()) {
            return tint();
          } else {
            return tunknown();
          }
        } else {
          return tunknown();
        }
      } else 
      if (operation == "-" || operation == "*" || operation == "/") {
        if (leftType != tint() || rightType != tint()) {
          return tunknown();
        } else {
          return tint();
        }
      } else if (operation == "\<" || operation == "\>" || operation == "\<=" || operation == "\>=")
      {
        if (leftType != tint() || rightType != tint()) {
          return tunknown();
        } else {
          return tbool();
        }
      } else if (operation == "&&" || operation == "||") {
        if (leftType != tbool() || rightType != tbool()) {
          return tunknown();
        } else {
          return tbool();
        }
      } else if (leftType != rightType) {
        return tunknown();
      } else {
        return tbool();
      }
    }
    case ref(AExpr expr, bool negated):
    {
      Type exprType = typeOf(expr, tenv, useDef);
      if (negated) {
        if (exprType == tbool()) {
          return tbool();
        } else {
          return tunknown();
        }
      } else {
        return exprType;
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
    case "string":
      return tstr();
    
    default:
      return tunknown();
  }
} 

bool isStringInSet(str s, set[str] strings) {
  for (str x <- strings) {
    if (x == s) {
      return true;
    }
  }
  return false;
}