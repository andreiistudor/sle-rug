module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  Use return_result = {};

  visit(f) {
    case ref(AId identifier): return_result += <identifier.src, identifier.name>; // use of identifier
  };

  return return_result;
}

Def defs(AForm f) {
  Def return_result = {};

  visit(f) {
    case question(_, AId identifier, _): return_result += <identifier.name, identifier.src>; // declaration of identifier
    case question(_, AId identifier, _, _): return_result += <identifier.name, identifier.src>; // declaration of identifier
  };

  return return_result; 
}