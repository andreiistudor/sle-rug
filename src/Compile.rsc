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
  list[HTMLElement] elements = [];
  visit(f) {
    case form(_, list[AQuestion] questions): 
    {
      for(AQuestion q <- questions) {
        elements += generateQuestion(q);
      }
    }
  }
  return html([title([text(f.name)]), head([h1([text(f.name)])]), body([form(elements)])]);
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
        element.readonly = "true";
        elements += element;
        element = lang::html::AST::label([text("Yes")]);
      } else if (qType.name == "integer") {
        element.\type = "number";
        element.readonly = "true";
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
      elements = [div(ifElements), br(), div(elements)];
    }
  }
  HTMLElement div = div(elements);
  div.style = "padding-left: 40px;";
  return div;
}

str form2js(AForm f) {
  return "";
}