module Eval

import AST;
import Resolve;

/*
 * Implements big-step semantics for QL
 *
 * NB: assumes the form is type- and name-correct.
 */
 

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
VEnv initialEnv(AForm f)
  = ( label.name: atype2value(qtype) | q: /simple_question(_, AId label, AType qtype)      := f ) 
  + ( label.name: atype2value(qtype) | q: /computed_question(_, AId label, AType qtype, _) := f )
  ;

Value atype2value(AType atype) {
	switch(atype) {
		case integer(): return vint(0);
		case boolean(): return vbool(false);
		case string(): 	return vstr("");
		
		default: 		throw "Unhandled type: <atype>";
	}
}

Value alit2value(lit_integer(int val))	= vint(val);
Value alit2value(lit_boolean(bool val))	= vbool(val);
Value alit2value(lit_string(str val)) 	= vstr(val);

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv)
  = bottomUpEval(f, updateVenvWithInput(inp, venv));

VEnv updateVenvWithInput(input(str question, Value answer), VEnv venv)
	= venv + (question : answer);

VEnv bottomUpEval(AForm f, VEnv venv)
	= bottomUpEval(f.questions, venv);

VEnv bottomUpEval(list[AQuestion] questions, VEnv venv)
	= (venv | bottomUpEval(question, it)  | question <- questions);

// no-op for simple question
VEnv bottomUpEval(simple_question(_, _, _), VEnv venv) 
	= venv;

// Evaluate expression for computed question.
VEnv bottomUpEval(computed_question(_, variable, _, expr), VEnv venv)
	= venv + (variable.name : bottomUpEvalExpression(expr, venv));
	
// - evaluating the sub-questions for a block.
VEnv bottomUpEval(block(list[AQuestion] questions), VEnv venv)
	= bottomUpEval(questions, venv);

// - evaluating the condition, and then the matching branch's sub-questions for conditionals.
VEnv bottomUpEval(conditional(\if(condition, list[AQuestion] questions)), VEnv venv)
	= bottomUpEvalExpression(condition, venv) == vbool(true) ? bottomUpEval(questions, venv) : venv;

VEnv bottomUpEval(conditional(ifelse(condition, list[AQuestion] thenQuestions, list[AQuestion] elseQuestions)), VEnv venv) 
	= bottomUpEvalExpression(condition, venv) == vbool(true) ? bottomUpEval(thenQuestions, venv) : bottomUpEval(elseQuestions, venv);

// Instead of unwrapping/wrapping all the time during execution,
// we use Rascal's built-in type tree and type->value reification to tell when we expect a certain type.
// Only at the outermost step of evaluating the expression we wrap it in a `Value` again.
Value bottomUpEvalExpression(AExpr e, VEnv venv) {
	switch(beer(#value, e, venv)) {
		case int x: 	return vint(x);
		case bool x: 	return vbool(x);
		case str x: 	return vstr(x);
	}
}

// 'beer' is shorthand for bottomUpEvalExpressionRaw.
&Output beer(type[&Output] result, &Input e, VEnv venv) {
	switch (e) {
		case ref(id(str x)): 					return unwrapValue(result, venv[x]);
		case lit(lit_integer(val)): 			return val;
		case lit(lit_boolean(val)): 			return val;
		case lit(lit_string(val)): 				return val;
		case not(AExpr inner): 					return !beer(#bool, inner);
		case plus(AExpr lhs, AExpr rhs): 		return beer(#int,   lhs, venv) +  beer(#int,   rhs, venv);
		case minus(AExpr lhs, AExpr rhs): 		return beer(#int,   lhs, venv) -  beer(#int,   rhs, venv);
		case mult(AExpr lhs, AExpr rhs): 		return beer(#int,   lhs, venv) *  beer(#int,   rhs, venv);
		case div(AExpr lhs, AExpr rhs): 		return beer(#int,   lhs, venv) /  beer(#int,   rhs, venv);
		case and(AExpr lhs, AExpr rhs): 		return beer(#bool,  lhs, venv) && beer(#bool,  rhs, venv);
		case or(AExpr lhs, AExpr rhs): 			return beer(#bool,  lhs, venv) || beer(#bool,  rhs, venv);
		case gt(AExpr lhs, AExpr rhs): 			return beer(#value, lhs, venv) >  beer(#value, rhs, venv);
		case lt(AExpr lhs, AExpr rhs): 			return beer(#value, lhs, venv) <  beer(#value, rhs, venv);
		case gte(AExpr lhs, AExpr rhs): 		return beer(#value, lhs, venv) >= beer(#value, rhs, venv);
		case lte(AExpr lhs, AExpr rhs): 		return beer(#value, lhs, venv) <= beer(#value, rhs, venv);
		case equal(AExpr lhs, AExpr rhs): 		return beer(#value, lhs, venv) == beer(#value, rhs, venv);
		case not_equal(AExpr lhs, AExpr rhs): 	return beer(#value, lhs, venv) != beer(#value, rhs, venv);
	};
}

&Output unwrapValue(type[&Output] result, Value val) {
	switch(val) {
		case vint(x):  return x;
		case vbool(x): return x;
		case vstr(x):  return x;
	}
}
