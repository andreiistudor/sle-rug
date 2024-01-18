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
      if (qType.name == "boolean") {
        element = input();
        element.id = identifier.name;
        element.\type = "checkbox";
        elements += element;
        element = lang::html::AST::label([text("Yes")]);
      } else if (qType.name == "integer") {
        element = input();
        element.id = identifier.name;
        element.\type = "number";
      } else if (qType.name == "string") {
        element = textarea([]);
        element.id = identifier.name;
      }
      elements += element;
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      HTMLElement element = h2([text(label)]);
      elements += element;
      if (qType.name == "boolean") {
        element = input();
        element.id = identifier.name;
        element.\type = "checkbox";
        element.disabled = "true";
        elements += element;
        element = lang::html::AST::label([text("Yes")]);
      } else if (qType.name == "integer") {
        element = input();
        element.id = identifier.name;
        element.\type = "number";
        element.disabled = "true";
      } else if (qType.name == "string") {
        element = textarea([]);
        element.id = identifier.name;
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
  jsScript += createShowFunction();
  jsScript += createHideFunction();
  jsScript += createEvaluateFunction(f);
  jsScript += createListeners();
  jsScript += createCallEvaluate();
  return jsScript;
}

str createCallEvaluate() {
  return "\n_evaluate();\n";
}

str createListeners() {
  str jsScript = "\n";
  jsScript += "document.addEventListener(\'DOMContentLoaded\', function() {\n";
  jsScript += tabs(1) + "var inputElements = document.getElementsByTagName(\'input\');\n";
  jsScript += tabs(1) + "Array.prototype.forEach.call(inputElements, function(element) {\n";
  jsScript += tabs(2) + "element.addEventListener(\'input\', function() {\n";
  jsScript += tabs(3) + "_evaluate();\n";
  jsScript += tabs(2) + "});\n";
  jsScript += tabs(1) + "});\n";
  jsScript += tabs(1) + "var textareaElements = document.getElementsByTagName(\'textarea\');\n";
  jsScript += tabs(1) + "Array.prototype.forEach.call(textareaElements, function(element) {\n";
  jsScript += tabs(2) + "element.addEventListener(\'input\', function() {\n";
  jsScript += tabs(3) + "_evaluate();\n";
  jsScript += tabs(2) + "});\n";
  jsScript += tabs(1) + "});\n";
  jsScript += "});\n";
  return jsScript;
}

str createShowFunction() {
  str jsScript = "\n";
  jsScript += "function _show(element) {\n";
  jsScript += tabs(1) + "element.parentNode.style.display = \'block\';\n";
  jsScript += "}\n";
  return jsScript;
}

str createHideFunction() {
  str jsScript = "\n";
  jsScript += "function _hide(element) {\n";
  jsScript += tabs(1) + "element.parentNode.style.display = \'none\';\n";
  jsScript += "}\n";
  return jsScript;
}

str createEvaluateFunction(AForm f) {
  str jsScript = "\n";
  jsScript += "function _evaluate() {\n";
  visit(f) {
    case form(_, list[AQuestion] questions): 
    {
      for(AQuestion q <- questions) {
        jsScript += createEvaluateFunction(q, 1);
      }
    }
  }
  jsScript += "}\n";
  return jsScript;
}

str createEvaluateFunction(AQuestion q, int indent) {
  str jsScript = "";
  switch (q) {
    case question(str label, AId identifier, AType qType):
    {
      jsScript += tabs(indent) + shown(identifier.name);
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      if (qType.name == "boolean") {
        jsScript += tabs(indent) + assign(identifier.name + ".checked", expr2js(expr));
      } else if (qType.name == "integer") {
        jsScript += tabs(indent) + assign(identifier.name + ".value", expr2js(expr));
      } else if (qType.name == "string") {
        jsScript += tabs(indent) + assign(identifier.name + ".value", expr2js(expr));
      }
      jsScript += tabs(indent) + shown(identifier.name);
    }
    case question(AExpr condition, list[AQuestion] ifQuestions):
    {
      jsScript += tabs(indent) + "if (" + expr2js(condition) + ") {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += createEvaluateFunction(q, indent + 1);
      }
      jsScript += tabs(indent) + "} else {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent + 1, q);
      }
      jsScript += tabs(indent) + "}\n";
    }
    case question(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
    {
      jsScript += tabs(indent) + "if (" + expr2js(condition) + ") {\n";
      for (AQuestion q <- ifQuestions) {
        jsScript += createEvaluateFunction(q, indent + 1);
      }
      for (AQuestion q <- elseQuestions) {
        jsScript += hidden(indent + 1, q);
      }
      jsScript += tabs(indent) + "} else {\n";
      for (AQuestion q <- elseQuestions) {
        jsScript += createEvaluateFunction(q, indent + 1);
      }
      for (AQuestion q <- ifQuestions) {
        jsScript += hidden(indent + 1, q);
      }
      jsScript += tabs(indent) + "}\n";
    }
  }
  return jsScript;
}

str shown(str id) {
  return "_show(" + id + ");\n";
}

str hidden(int indent, AQuestion q) {
  str jsScript = "";
  switch (q) {
    case question(str label, AId identifier, AType qType):
    {
      jsScript += tabs(indent) + "_hide(" + identifier.name + ");\n";
    }
    case question(str label, AId identifier, AType qType, AExpr expr):
    {
      jsScript += tabs(indent) + "_hide(" + identifier.name + ");\n";
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
      case vstr(s) :
      {
        jsScript += assign(key, getElementById(key));
        jsScript += assign(key + ".value", "\"" + s + "\"");
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

str tabs(int n) {
  str s = "";
  for (int i <- [0..n]) {
    s += "\t";
  }
  return s;
}

str expr2js(AExpr expr) {
  switch (expr) {
    case ref(AId id):
    {
      if (venv[id.name] is vint) {
        return "+" + id.name + ".value";
      } else if (venv[id.name] is vbool) {
        return id.name + ".checked";
      } else if (venv[id.name] is vstr) {
        return id.name + ".value";
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
    case ref(str s):
    {
      return "\"" + s + "\"";
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
