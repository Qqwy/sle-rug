module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast((SimpleQuestion)`<Str name> <Id id> : <Type ftype>`) {
	return simple_question("<name>", <"<id>","<ftype>">);
}

AQuestion cst2ast(Question q) {
  throw "Not yet implemented";
}

// TODO WM: Maybe refactor to separate function heads?
//          Especially the `src=l@\loc` stuff seems repetitive.
AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id(x), src=x@\loc);
    case (Expr)`<Literal literal>`: return lit("<literal>", src=literal@\loc);
    case (Expr)`!<Expr expr>`: return not(cst2ast(expr), src=e@\loc);
    case (Expr)`<Expr lhs>*<Expr rhs>`: return mult(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>/<Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>+<Expr rhs>`: return plus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>-<Expr rhs>`: return minus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>&&<Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>||<Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\><Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<<Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<=<Expr rhs>`: return lte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\>=<Expr rhs>`: return gte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>==<Expr rhs>`: return equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>!=<Expr rhs>`: return not_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`boolean`: return boolean();
    case (Type)`string`: return string();
    case (Type)`integer`: return integer();
    default: throw "Unhandled type: <t>";
  };
}
