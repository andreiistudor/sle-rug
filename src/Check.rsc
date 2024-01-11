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
    case form(_, list[AQuestion] questions): {
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
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      int count_occurances = 0;

      // Check for duplicate labels
      for (<_, _, str label, _> <- tenv) {
        if (label_q == label) {
          count_occurances += 1;
        }
      }

      if(count_occurances > 1)
        msgs += { warning("Duplicate labels detected", id.src) };
    }
    case question(str label_q, AId id, AType qType, AExpr expr):
    {
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && typeOfByName(qType.name) != myType) {
          msgs += { error("Questions with the same name but different types", id.src) };
        }
      }

      int count_occurances = 0;

      // Check for duplicate labels
      for (<_, _, str label, _> <- tenv) {
        if (label_q == label) { // Assuming identifier.name is unique
          count_occurances += 1;
        }
      }

      if(count_occurances > 1) 
        msgs += { warning("Duplicate labels detected", id.src) };

    }
    case question(AExpr expr, list[AQuestion] ifQuestions):
    {
      for(AQuestion q <- ifQuestions) {
        msgs += check(q, tenv, useDef); // Check each question in the if statement list
      }
    }
    case question(AExpr expr, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
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

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
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

