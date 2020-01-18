module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import ValueIO; // for parsing simple integers, strings and booleans.
extend lang::std::Id;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf)
  = cst2ast(sf.top);

AForm cst2ast(sf: (Form)`form <Id name> { <Question* questions> }`)
  = form("<name>", [cst2ast(question) | question <- questions], src = sf@\loc);


AQuestion cst2ast(Question question) {
  switch (question) {
  	case (Question)`<SimpleQuestion q>`: return cst2ast(q);
  	case (Question)`<ComputedQuestion q>`: return cst2ast(q);
  	case (Question)`<Block b>`: return block(cst2ast(b));
  	case (Question)`<Conditional c>`: return conditional(cst2ast(c));

    default: throw "Unhandled question type: <question>";
  }
}

AQuestion cst2ast(c: (SimpleQuestion)`<Str name> <Id id> : <Type qtype>`)
	= simple_question(readTextValueString(#str, "<name>"), cst2ast(id), cst2ast(qtype), src = c@\loc);



AQuestion cst2ast(c : (ComputedQuestion)`<Str name> <Id id> : <Type ftype> = <Expr expr>`)
	= computed_question(readTextValueString(#str, "<name>"), cst2ast(id), cst2ast(ftype), cst2ast(expr), src = c@\loc);


list[AQuestion] cst2ast((Block)`{<Question *questions>}`)
	= [cst2ast(question) | question <- questions];


AConditional cst2ast(Conditional c) {
	switch(c) {
		case (Conditional)`if <Condition cond><Block ifblock> else <Block elseblock>`: return ifelse(cst2ast(cond), cst2ast(ifblock), cst2ast(elseblock), src = c@\loc);
		case (Conditional)`if <Condition cond><Block ifblock>`: return \if(cst2ast(cond), cst2ast(ifblock), src = c@\loc);
	
	    default: throw "Unhandled conditional: <c>";
	}
}

AExpr cst2ast((Condition)`(<Expr e>)`)
	= cst2ast(e);

AExpr cst2ast(Expr e) {
  switch (e) {
	case (Expr)`(<Expr expr>)`: 			return cst2ast(expr, src=e@\loc);
    case (Expr)`<Id x>`: 					return ref(cst2ast(x), src=x@\loc);
    case (Expr)`<Str literal>`: 			return lit(lit_string(readTextValueString(#str, "<literal>")), src=literal@\loc);
    case (Expr)`<Int literal>`: 			return lit(lit_integer(readTextValueString(#int, "<literal>")), src=literal@\loc);
    case (Expr)`<Bool literal>`: 			return lit(lit_boolean(readTextValueString(#bool, "<literal>")), src=literal@\loc);
    case (Expr)`!<Expr expr>`: 				return not(cst2ast(expr), src=e@\loc);
    case (Expr)`<Expr lhs>*<Expr rhs>`: 	return mult(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>/<Expr rhs>`: 	return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>+<Expr rhs>`: 	return plus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>-<Expr rhs>`: 	return minus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>&&<Expr rhs>`: 	return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>||<Expr rhs>`: 	return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\><Expr rhs>`: 	return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<<Expr rhs>`: 	return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<=<Expr rhs>`: 	return lte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\>=<Expr rhs>`: 	return gte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>==<Expr rhs>`: 	return equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>!=<Expr rhs>`: 	return not_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`boolean`: 	return boolean(src = t@\loc);
    case (Type)`string`: 	return string(src = t@\loc);
    case (Type)`integer`: 	return integer(src = t@\loc);
    default: throw "Unhandled type: <t>";
  };
}

AId cst2ast(Id x)
  = id("<x>", src=x@\loc);
