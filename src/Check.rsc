module Check

import AST;
import Resolve;
import Message; // see standard library


data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// Since most function pass on both the Type Environment and the Used Definitions
// to their inner functions without working on them in complex ways,
// combining them to a single structure makes the code much more readable,
// since now there is only as single thing being passed around everywhere..
alias CheckEnv = tuple[TEnv tenv, UseDef useDef];

// Deep matches on the AST nodes of questions
// to collect their definitions, which together make up the type environment.
TEnv collect(AForm f) {
  return 
    { <label.src, name, label.name, atype2type(qtype)> | q: /simple_question(str name, AId label, AType qtype)      := f } 
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

/* Performs a semantic check on the entire form:
  - Prevents duplicate questions with different types.
  - Warns for re-used labels (for questions with different types or names).
  - Prevents operators receiving the wrong type of arguments.
  - Prevents references that refer to questions that do not exist.
  
  TODO maybe check for cycles?
*/
set[Message] check(AForm f, CheckEnv checkEnv)
	= check(f.questions, checkEnv);


set[Message] check(list[AQuestion] questions, CheckEnv checkEnv)
	= { *check(q, checkEnv) | q <- questions };


set[Message] check(simple_question(str label, AId variable, AType qtype), CheckEnv checkEnv) 
	= preventRedeclaration(variable, qtype, checkEnv)
	+ warnIfDuplicateLabel(variable, label, checkEnv);

set[Message] check(computed_question(str label, AId variable, AType qtype, AExpr expr), CheckEnv checkEnv)
	= preventRedeclaration(variable, qtype, checkEnv)
	+ warnIfDuplicateLabel(variable, label, checkEnv)
	+ check(expr, checkEnv)
	+ requireArgumentType(expr, atype2type(qtype), checkEnv);

set[Message] check(block(list[AQuestion] questions), CheckEnv checkEnv)
	= check(questions, checkEnv);

set[Message] check(conditional(\if(condition, list[AQuestion] questions)), CheckEnv checkEnv)
	= requireArgumentType(condition, tbool(), checkEnv)
	+ check(condition, checkEnv)
	+ check(questions, checkEnv);

set[Message] check(conditional(ifelse(condition, list[AQuestion] thenQuestions, list[AQuestion] elseQuestions)), CheckEnv checkEnv)
	= requireArgumentType(condition, tbool(), checkEnv)
	+ check(condition, checkEnv)
	+ check(thenQuestions, checkEnv)
	+ check(elseQuestions, checkEnv);

set[Message] preventRedeclaration(AId variable, AType qtype, CheckEnv checkEnv)
	= {
	error("Redeclaration of <variable.name>", variable.src) 
	| <loc def, _, x, Type \type> <- definitionsWithSameName(variable, checkEnv)
	, \type != atype2type(qtype)
	};

set[Message] warnIfDuplicateLabel(AId variable, str label, CheckEnv checkEnv)
	= { 
	warning("Duplicate label `<label>` in use for `<variable.name>`", def)
	| <loc def, _, x, Type \type> <-  definitionsWithSameLabel(label, variable, checkEnv)
	};

TEnv definitionsWithSameName(AId variable, CheckEnv checkEnv)
	= 
	{ definition
	| definition: <loc def, _, x, Type \type> <- checkEnv.tenv 
	, def != variable.src 
	, x == variable.name
	};
	
TEnv definitionsWithSameLabel(str label, AId variable, CheckEnv checkEnv)
	= 
	{ definition
	| definition: <loc def, label, _, Type \type> <- checkEnv.tenv 
	, def != variable.src 
	};

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, CheckEnv checkEnv) {
  switch (e) {
    case ref(id(str x), src = loc u):		return requireQuestionDefined(x, u,     checkEnv);
    case lit(_): 							return {};
    case not(AExpr inner):					return checkUnaryOp(inner, tbool(),     checkEnv);
    case plus(AExpr lhs, AExpr rhs):	 	return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case minus(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case mult(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case div(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case and(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tbool(), checkEnv);
    case or(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tbool(), checkEnv);
    case gt(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case lt(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case gte(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case lte(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(),  checkEnv);
    case equal(AExpr lhs, AExpr rhs): 		return checkBinaryOpSameArbitraryType(lhs, rhs, checkEnv);
    case not_equal(AExpr lhs, AExpr rhs): 	return checkBinaryOpSameArbitraryType(lhs, rhs, checkEnv);
    
    default: 								assert false : "Unhandled expression <e> in semantic checking algorithm.";
  }
}

set[Message] requireQuestionDefined(str name, loc u, CheckEnv checkEnv)
	= { error("Reference to undefined question with name `<name>`", u) | checkEnv.useDef[u] == {} };

set[Message] checkUnaryOp(AExpr inner, Type required_type, CheckEnv checkEnv)
	= requireArgumentType(inner, required_type, checkEnv)
	+ check(inner, checkEnv);

set[Message] checkBinaryOp(AExpr lhs, AExpr rhs, Type required_type, CheckEnv checkEnv)
	= requireBinOpTypes(lhs, rhs, required_type, checkEnv)
	+ check(lhs, checkEnv)
	+ check(rhs, checkEnv);

set[Message] requireBinOpTypes(AExpr lhs, AExpr rhs, Type required_type, CheckEnv checkEnv) 
	= requireArgumentType(lhs, required_type, checkEnv)
	+ requireArgumentType(rhs, required_type, checkEnv);

set[Message] checkBinaryOpSameArbitraryType(AExpr lhs, AExpr rhs, CheckEnv checkEnv)
{
	lhs_type = typeOf(lhs, checkEnv);
	rhs_type = typeOf(rhs, checkEnv);
	other_messages = check(lhs, checkEnv) + check(rhs, checkEnv);
	if (lhs_type != rhs_type) {
		return {
		error("Incompatible argument types (expected both arguments to be the same, got `<print_type(lhs_type)>` and `<print_type(rhs_type)>`)", lhs.src), 
		error("Incompatible argument types (expected both arguments to be the same, got `<print_type(lhs_type)>` and `<print_type(rhs_type)>`)", rhs.src)} 
		+ other_messages;
	} else {
		return other_messages;
	}
}

set[Message] requireArgumentType(AExpr expr, Type required_type, CheckEnv checkEnv)
	= {error("Incompatible argument type (expected `<print_type(required_type)>` but got `<print_type(real_type)>`)", expr.src) | real_type :=  typeOf(expr, checkEnv), real_type != required_type};

Type typeOf(AExpr e, CheckEnv checkEnv) {
  switch (e) {
    case ref(id(str x), src = loc u):   return lookupReferenceType(x, u, checkEnv);
    case lit(ALit l): 					return typeOf(l);
	case not(_): 						return tbool();
	case mult(_, _): 					return tint();
	case div(_, _): 					return tint();
	case plus(_, _): 					return tint();
	case minus(_,_): 					return tint();
	case and(_,_): 						return tbool();
	case or(_,_): 						return tbool();
	case gt(_,_): 						return tbool();
	case lt(_,_): 						return tbool();
	case gte(_,_): 						return tbool();
	case lte(_,_): 						return tbool();
	case equal(_,_): 					return tbool();
	case not_equal(_,_):				return tbool();
	
	default: 							return tunknown(); 
  }
}

Type lookupReferenceType(str x, loc u, CheckEnv checkEnv) {
  if (<u, loc d> <- checkEnv.useDef, <d, _, x, Type t> <- checkEnv.tenv) {
    return t;
  } else {
  	return tunknown();
  }
}

Type typeOf(lit_integer(_)) = tint();
Type typeOf(lit_boolean(_)) = tbool();
Type typeOf(lit_string(_)) 	= tstr();

str print_type(tint()) = "integer";
str print_type(tbool()) = "boolean";
str print_type(tstr()) = "string";
str print_type(tunknown()) = "unknown";

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
