module Eval

import AST;
import Resolve;
import IO;
import String;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();

  visit(f) {
    case question(_, AId identifier, AType qType):
      venv[identifier.name] = defaultValue(qType.name);
    case question(_, AId identifier, _, AExpr expr):
      venv[identifier.name] = eval(expr, venv);
  }

  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  visit(f) {
    case form(_, list[AQuestion] questions):
    {
      for(AQuestion q <- questions) {
        venv = eval(q, inp, venv);
      }
    }
  }

  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  visit(q) {
    case question(_, AId identifier, AType qType):
      if (identifier.name == inp.question) {
        venv[identifier.name] = inp.\value;
      }
    case question(_, AId identifier, _, AExpr expr):
      if (identifier.name == inp.question) {
        venv[identifier.name] = inp.\value;
      } else {
      venv[identifier.name] = eval(expr, venv);
      }
    case question(AExpr expr, list[AQuestion] ifQuestions):
      if(valueToBool(eval(expr, venv))) {
        for(AQuestion q <- ifQuestions) {
          venv = eval(q, inp, venv);
        }
      }
    case question(AExpr expr, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
      if(valueToBool(eval(expr, venv))) {
        for(AQuestion q <- ifQuestions) {
          venv = eval(q, inp, venv);
        }
      } else {
        for(AQuestion q <- elseQuestions) {
          venv = eval(q, inp, venv);
        }
      }
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case ref(bool b): return vbool(b);
    case ref(int n): return vint(n);
    case ref(AExpr expr, bool negated):
    {
      if(!negated) return eval(expr, venv);
      else return vbool(!valueToBool(eval(expr, venv)));
    }
    case ref(AExpr lhs, str op, AExpr rhs):
    {
      Value left = eval(lhs, venv);
      Value right = eval(rhs, venv);

      println("Left    Right");
      print(left);
      print("  <op>  ");
      print(right);
      println(" -- -- ");

      switch (op) {
        case "+": return vint(valueToInt(left) + valueToInt(right));
        case "-": return vint(valueToInt(left) - valueToInt(right));
        case "*": return vint(valueToInt(left) * valueToInt(right));
        case "/": return vint(valueToInt(left) / valueToInt(right));
        case "\<": return vbool(valueToInt(left) < valueToInt(right));
        case "\<=": return vbool(valueToInt(left) <= valueToInt(right));
        case "\>": return vbool(valueToInt(left) > valueToInt(right));
        case "\>=": return vbool(valueToInt(left) >= valueToInt(right));
        case "==": return vbool(valueToInt(left) == valueToInt(right));
        case "!=": return vbool(valueToInt(left) != valueToInt(right));
        case "&&": return vbool(valueToBool(left) && valueToBool(right));
        case "||": return vbool(valueToBool(left) || valueToBool(right));
        case "!": return vbool(!valueToBool(left));

        default: throw "Unsupported operator <op>";
      }
    }

    default: throw "Unsupported expression <e>";
  }
}

Value defaultValue(str qType) {
  switch (qType) {
    case "integer": return vint(0);
    case "boolean": return vbool(false);
    case "str": return vstr("");

    default: throw "Unsupported type <qType>";
  }
}

bool valueToBool(Value v) {
  switch (v) {
    case vbool(b): return b;
    default: throw "Expected boolean value";
  }
}

int valueToInt(Value v) {
  switch (v) {
    case vint(n): return n;
    default: throw "Expected integer value";
  }
}