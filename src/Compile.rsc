module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

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

void compile(AForm f) {
  // writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  list[HTMLElement] formElements = [];

  visit(f) {
    case question(str text, AId id, AType qType):
      formElements += [createQuestionElement(text, id, qType)];
    case question(str text, AId id, AType qType, AExpr expr):
      formElements += [createComputedQuestionElement(text, id, qType, expr)];
  }

  return html([
    body([
      form([
        div(formElements)
      ])
    ])
  ]);
}

HTMLElement createQuestionElement(str label, AId id, AType qType) {
  switch(qType.name) {
    case "boolean":
      return div([
        div([text("Boolean")])
      ]);
    case "string":
      return div([
        div([text("String")])
      ]);
    case "integer":
      return div([
        div([text("Integer")])
      ]);

    default:
      return p([text("Unsupported type <qType.name>")]);
  }
}

HTMLElement createComputedQuestionElement(str text, AId id, AType qType, AExpr expr) {
  return div([

  ]);
}

str form2js(AForm f) {
  return "";
}
