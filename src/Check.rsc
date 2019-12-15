module Check

import AST;
import Resolve;
import Message; // see standard library
import IO; //todo: remove

import CST2AST; // For testing
import Syntax; // For testing
import ParseTree; // For testing


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
  return 
    { <label.src, name, label.name, atype2type(qtype)> | q: /simple_question(str name, AId label, AType qtype) := f } 
  + { <label.src, name, label.name, atype2type(qtype)> | q: /computed_question(str name, AId label, AType qtype, _) := f } ;
  ;
}

Type atype2type(AType atype) {
	switch(atype) {
		case integer(): return tint();
		case boolean(): return tbool();
		case string(): return tstr();
		default: throw "Unhandled type: <atype>";
	}
}


set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return { *check(q, tenv, useDef) | q <- f.questions };
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  if (simple_question(_, AId variable, AType qtype) := q || 
  	  computed_question(_, AId variable, AType qtype, _) := q)
  	return {\type != atype2type(qtype) ? error("Redeclaration of <variable.name>", def) : 
  	warning("Duplicate label of <variable.name>", def) | str x := variable.name,  
  	<loc def, _, x, Type \type> <- tenv, def != variable.src};
  
  if (block(list[AQuestion] questions) := q ||
  	conditional(\if(condition, list[AQuestion] questions)) := q)
  	return { *check(qt, tenv, useDef) | qt <- questions } + check(condition, tenv, useDef);
  
  if (conditional(ifelse(condition, list[AQuestion] q1, list[AQuestion] q2)) := q)
  	return { *check(qt, tenv, useDef) | qt <- q1 + q2 } + check(condition, tenv, useDef);
  
  return {};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(str x), src = loc u):			return requireQuestionDefined(x, u, tenv, useDef);
    case not(AExpr inner):					return requireArgumentType(inner, tbool(), tenv, useDef);
    case plus(AExpr lhs, AExpr rhs):	 	return requireBinOpTypes(lhs, rhs, tint(), tenv, useDef);
    case minus(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tint(), tenv, useDef);
    case mult(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tint(), tenv, useDef);
    case div(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tint(), tenv, useDef);
    case and(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case or(AExpr lhs, AExpr rhs): 			return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case gt(AExpr lhs, AExpr rhs): 			return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case lt(AExpr lhs, AExpr rhs): 			return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case gte(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case lte(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case equal(AExpr lhs, AExpr rhs): 		return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    case not_equal(AExpr lhs, AExpr rhs): 	return requireBinOpTypes(lhs, rhs, tbool(), tenv, useDef);
    
    default: 								assert false : "Unhandled expression in semantic checking algorithm.";
  }
}

set[Message] requireQuestionDefined(str name, loc u, TEnv tenv, UseDef useDef)
	= { error("Reference to undefined question with name `<name>`", u) | useDef[u] == {} };

set[Message] requireBinOpTypes(AExpr lhs, AExpr rhs, Type required_type, TEnv tenv, UseDef useDef) 
	= requireArgumentType(lhs, required_type, tenv, useDef)
	+ requireArgumentType(rhs, required_type, tenv, useDef);


set[Message] requireArgumentType(AExpr expr, Type required_type, TEnv tenv, UseDef useDef)
	= {error("Incompatible argument type", expr.src) | typeOf(expr, tenv, useDef) != required_type};

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(str x), src = loc u):   return lookupReferenceType(x, u, tenv, useDef);
    case lit(ALit l): 				return typeOf(l);
	case not(_): 					return tbool();
	case mult(_, _): 				return tint();
	case div(_, _): 				return tint();
	case plus(_, _): 				return tint();
	case minus(_,_): 				return tint();
	case and(_,_): 					return tbool();
	case or(_,_): 					return tbool();
	case gt(_,_): 					return tbool();
	case lt(_,_): 					return tbool();
	case gte(_,_): 					return tbool();
	case lte(_,_): 					return tbool();
	case equal(_,_): 				return tbool();
	case not_equal(_,_):			return tbool();
	default: 						return tunknown(); 
  }
}

Type lookupReferenceType(str x, loc u, TEnv tenv, UseDef useDef) {
  if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
    return t;
  } else {
  	return tunknown();
  }
}

Type typeOf(lit_integer(_)) = tint();
Type typeOf(lit_boolean(_)) = tbool();
Type typeOf(lit_string(_)) 	= tstr();


/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */

// To use on individual expressions and other snippets.
// Will not call 'resolve' or 'collect' so reference-based checks
//  cannot be tested this way.
set[Message] parseCheck(type[&T<:Tree] begin, str input) {
	ast = parse2ast(begin, input);
	return check(ast, {}, {});
}

// To use on a whole form
set[Message] parseResolveCollectCheck(str input) {
	ast = parse2ast(#start[Form], input);
	return check(ast, collect(ast), resolve(ast).useDef);
}
 
test bool allowsPlusIntExpr()
 	 = {} := parseCheck(#Expr, "1 + 2");

test bool rejectIntNotExpr()
 	 = {error("Incompatible argument type", _)} := parseCheck(#Expr, "!42");

 
test bool rejectPlusBoolExpr()
 	 = {error("Incompatible argument type", _)} := parseCheck(#Expr, "1 + true");


test bool rejectPlusBothBoolExpr()
 	 = {error("Incompatible argument type", _), error("Incompatible argument type", _)} := parseCheck(#Expr, "false + true");

test bool rejectUndefinedQuestionReference()
	= {error(_, _)} := parseCheck(#Expr, "myvariable");

test bool allowDefinedQuestionReference()
	= {} := parseResolveCollectCheck("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = foo + 2
	}
	");

test bool rejectUndefinedQuestionReference()
	= {error(_, _)} := parseResolveCollectCheck("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = baz + 2
	}
	");

