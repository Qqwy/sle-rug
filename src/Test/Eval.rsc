module Test::Eval

import Test::Helper;

import Eval;
import AST;
import Syntax;

VEnv buildEnvFromInput(str input) {
	ast = parse2ast(#start[Form], input);
	return initialEnv(ast);
}

VEnv evalOnceFromString(str inputForm, str questionToAlter, Value newValue) {
	ast = parse2ast(#start[Form], inputForm);
	env = initialEnv(ast);
	inp = input(questionToAlter, newValue);
	return evalOnce(ast, inp, env);
}

test bool buildSimpleEnv()
	 = ("bar" : vint(0), "mybool" : vbool(false)) == buildEnvFromInput("form a {
		\"foo\" mybool : boolean
		if(mybool) {
			\"bar\" bar : integer
		}
	}
	");

test bool bottomUpPlus(int x, int y)
	= vint(x + y) == bottomUpEvalExpression(plus(lit(lit_integer(x)), lit(lit_integer(y))), ());

test bool bottomUpMult(int x, int y)
	= vint(x * y) == bottomUpEvalExpression(mult(lit(lit_integer(x)), lit(lit_integer(y))), ());

test bool bottomUpMinus(int x, int y)
	= vint(x - y) == bottomUpEvalExpression(minus(lit(lit_integer(x)), lit(lit_integer(y))), ());

test bool bottomUpDiv(int x, int y)
	= y == 0 || vint(x / y) == bottomUpEvalExpression(div(lit(lit_integer(x)), lit(lit_integer(y))), ());

test bool bottomUpAnd(bool x, bool y)
	= vbool(x && y) == bottomUpEvalExpression(and(lit(lit_boolean(x)), lit(lit_boolean(y))), ());

test bool bottomUpOr(bool x, bool y)
	= vbool(x || y) == bottomUpEvalExpression(or(lit(lit_boolean(x)), lit(lit_boolean(y))), ());

test bool bottomUpGtBool(bool x, bool y)
	= vbool(x > y) == bottomUpEvalExpression(gt(lit(lit_boolean(x)), lit(lit_boolean(y))), ());

test bool bottomUpGtInt(int x, int y)
	= vbool(x > y) == bottomUpEvalExpression(gt(lit(lit_integer(x)), lit(lit_integer(y))), ());

test bool bottomUpGtStr(str x, str y)
	= vbool(x > y) == bottomUpEvalExpression(gt(lit(lit_string(x)), lit(lit_string(y))), ());

test bool simpleEvalOnce()
	= ("foo": vint(42), "bar": vint(75)) == evalOnceFromString("form a {
		\"foo\" foo : integer
		if(foo \> 20) {
			\"bar\" bar : integer = foo + 33
		}
	}
	", "foo", vint(42));
	
test bool simpleEvalOnceConditional()
	= ("foo": vint(-1), "bar": vint(999)) == evalOnceFromString("form a {
		\"foo\" foo : integer
		if(foo \> 20) {
			\"bar\" bar : integer = foo + 33
		} else {
			\"bar\" bar : integer = foo + 1000
		}
	}
	", "foo", vint(-1));
