module Compile

import AST;
import Resolve;
import IO;
import Eval;
import lang::html::AST; // see standard library
import lang::html::IO;
import Map;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

VEnv venv;

void compile(AForm f) {
  venv = initialEnv(f);
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  list[HTMLElement] elements = [];
  visit(f) {
    case form(_, list[AQuestion] questions): 
    {
      for(AQuestion q <- questions) {
        elements += generateQuestion(q);
      }
    }
  }
  HTMLElement scriptSrc = script([]);
  scriptSrc.src = f.src[extension="js"].file;
  return html([title([text(f.name)]), head([h1([text(f.name)])]), body([form(elements), scriptSrc])]);
}

HTMLElement generateQuestion(AQuestion q) {
  list[HTMLElement] elements = [];
  switch (q) {
    case question(str label, AId identifier, AType qType):
    {
      HTMLElement element = h2([text(label)]);
      elements += element;
      element = input();
      element.id = identifier.name;
      if (qType.name == "boolean") {
        element.\type = "checkbox";
        elements += element;
        element = lang::html::AST::label([text("Yes")]);
      } else if (qType.name == "integer") {
        element.\type = "number";
      }
      elements += element;
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      HTMLElement element = h2([text(label)]);
      elements += element;
      element = input();
      element.id = identifier.name;
      if (qType.name == "boolean") {
        element.\type = "checkbox";
        element.disabled = "true";
        elements += element;
        element = lang::html::AST::label([text("Yes")]);
      } else if (qType.name == "integer") {
        element.\type = "number";
        element.disabled = "true";
      }
      elements += element;
    }
    case question(AExpr condition, list[AQuestion] ifQuestions):
    {
      for (AQuestion q <- ifQuestions) {
        elements += generateQuestion(q);
      }
    }
    case question(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      list[HTMLElement] ifElements = [];
      for (AQuestion q <- ifQuestions) {
        ifElements += generateQuestion(q);
      }
      for (AQuestion q <- elseQuestions) {
        elements += generateQuestion(q);
      }
      elements = [div(ifElements), div(elements)];
    }
  }
  HTMLElement div = div(elements);
  div.style = "padding-left: 40px;";
  return div;
}

str form2js(AForm f) {
  str jsScript = "";
  jsScript += setDefaultValues(f);
  jsScript += createEvaluateFunction(f);
  jsScript += "document.addEventListener(\'DOMContentLoaded\', function() {\n";
  jsScript += spaces(2) + "var inputElements = document.getElementsByTagName(\'input\');\n";
  jsScript += spaces(2) + "Array.prototype.forEach.call(inputElements, function(element) {\n";
  jsScript += spaces(4) + "element.addEventListener(\'input\', function() {\n";
  jsScript += spaces(6) + "evaluate();\n";
  jsScript += spaces(4) + "});\n";
  jsScript += spaces(2) + "});\n";
  jsScript += "});\n";
  jsScript += "\n";
  jsScript += "evaluate();\n";
  return jsScript;
}

str createEvaluateFunction(AForm f) {
  str jsScript = "\n";
  jsScript += "function evaluate() {\n";
  visit(f) {
    case form(_, list[AQuestion] questions): 
    {
      for(AQuestion q <- questions) {
        jsScript += createEvaluateFunction(q, 2);
      }
    }
  }
  jsScript += "}\n";
  jsScript += "\n";
  return jsScript;
}

str createEvaluateFunction(AQuestion q, int indent) {
  str jsScript = "";
  switch (q) {
    case question(str label, AId identifier, AType qType):
    {
      jsScript += spaces(indent) + shown(identifier.name);
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      if (qType.name == "boolean") {
        jsScript += spaces(indent) + assign(identifier.name + ".checked", expr2js(expr));
      } else if (qType.name == "integer") {
        jsScript += spaces(indent) + assign(identifier.name + ".value", expr2js(expr));
      }
      jsScript += spaces(indent) + shown(identifier.name);
    }
    case question(AExpr condition, list[AQuestion] ifQuestions):
    {
      jsScript += spaces(indent) + "if (" + expr2js(condition) + ") {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += createEvaluateFunction(q, indent + 2);
      }
      jsScript += spaces(indent) + "} else {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent + 2, q);
      }
      jsScript += spaces(indent) + "}\n";
    }
    case question(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      jsScript += spaces(indent) + "if (" + expr2js(condition) + ") {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += createEvaluateFunction(q, indent + 2);
      }
      for (AQuestion q <- elseQuestions) {
        jsScript += hidden(indent + 2, q);
      }
      jsScript += spaces(indent) + "} else {\n";
      for (AQuestion q <- elseQuestions) {
        jsScript += createEvaluateFunction(q, indent + 2);
      }
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent + 2, q);
      }
      jsScript += spaces(indent) + "}\n";
    }
  }
  return jsScript;
}

str shown(str id) {
  return id + ".parentNode.style.display = \'block\';\n";
}

str hidden(int indent, AQuestion q) {
  str jsScript = "";
  switch (q) {
    case question(str label, AId identifier, AType qType):
    {
      jsScript += spaces(indent) + identifier.name + ".parentNode.style.display = \'none\';\n";
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      jsScript += spaces(indent) + identifier.name + ".parentNode.style.display = \'none\';\n";
    }
    case question(AExpr condition, list[AQuestion] ifQuestions):
    {
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent, q);
      }
    }
    case question(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent, q);
      }
      for (AQuestion q <- elseQuestions) {
        jsScript += hidden(indent, q);
      }
    }
  }
  return jsScript;
}

str setDefaultValues(AForm f) {
  str jsScript = "";
  for (str key <- venv) {
    switch(venv[key]) {
      case vint(n) :
      {
        jsScript += assign(key, getElementById(key));
        jsScript += assign(key + ".value", int2str(n));
      }
      case vbool(b) :
      {
        jsScript += assign(key, getElementById(key));
        if (b) {
          jsScript += assign(key + ".checked", "true");
        } else {
          jsScript += assign(key + ".checked", "false");
        }
      }
    }
  }
  return jsScript;
}

str assign(str left, str right) {
  return left + " = " + right + ";\n";
}

str getElementById(str id) {
  return "document.getElementById(\'" + id + "\')";
}

str int2str(int n) {
  return "<n>";
}

str spaces(int n) {
  str s = "";
  for (int i <- [0..n]) {
    s += " ";
  }
  return s;
}

str expr2js(AExpr expr) {
  switch (expr) {
    case ref(AId id):
    {
      if (venv[id.name] is vint) {
        return id.name + ".value";
      } else if (venv[id.name] is vbool) {
        return id.name + ".checked";
      } else {
        return "";
      }
    }
    case ref(bool b):
    {
      if (b) {
        return "true";
      } else {
        return "false";
      }
    }
    case ref(int n):
    {
      return int2str(n);
    }
    case ref(AExpr left, str operation, AExpr right):
    {
      return expr2js(left) + " " + operation + " " + expr2js(right);
    }
    case ref(AExpr expr, bool negated):
    {
      if (negated) {
        return "!" + expr2js(expr);
      } else {
        return "(" + expr2js(expr) + ")";
      }
    }
    default:
    {
      return "";
    }
  }
}
