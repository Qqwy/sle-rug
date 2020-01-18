module Test::Check

import Test::Helper;
import Syntax;
import AST;


test bool allowsPlusIntExpr()
 	 = {} := parseCheck(#Expr, "1 + 2");

test bool rejectIntNotExpr()
 	 = {error("Incompatible argument type (expected `boolean` but got `integer`)", _)} := parseCheck(#Expr, "!42");
 
test bool rejectPlusBoolExpr()
 	 = {error("Incompatible argument type (expected `integer` but got `boolean`)", _)} := parseCheck(#Expr, "1 + true");

test bool rejectPlusBothBoolExpr()
 	 = 
 	 { error("Incompatible argument type (expected `integer` but got `boolean`)", _)
 	 , error("Incompatible argument type (expected `integer` but got `boolean`)", _)
 	 } 
 	 := parseCheck(#Expr, "false + true");

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
	= 
	{ error("Reference to undefined question with name `baz`",_)
  	, error("Incompatible argument type (expected `integer` but got `unknown`)",_)
  	}
	:= parseResolveCollectCheck("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = baz + 2
	}
	");

test bool rejectQuestionReferenceOfDifferentType()
	= 
	{error("Incompatible argument type (expected `integer` but got `boolean`)", _)
	} 
	:= parseResolveCollectCheck("
	form a {
		\"foo\" mybool : boolean
		\"bar\" bar : integer = mybool + 2
	}
	");
	
test bool warnForDuplicateLabel()
	= 
	{ warning("Duplicate label `Do you want a cup of tea?` in use for `cupOfTea`", _)
	, warning("Duplicate label `Do you want a cup of tea?` in use for `housePrice`", _)
	} 
	:= parseResolveCollectCheck("
	form a {
		\"Do you want a cup of tea?\" cupOfTea : boolean
		\"Do you want a cup of tea?\" housePrice : integer
	}");
	
	
test bool acceptSimpleConditional()
	= 
	{} := parseResolveCollectCheck("
	form a {
		\"foo\" mybool : boolean
		if(mybool) {
			\"bar\" bar : integer
		}
	}
	");
	
test bool rejectNonbooleanConditional()
	= 
	{error("Incompatible argument type (expected `boolean` but got `integer`)", _)} 
	:= parseResolveCollectCheck("
	form a {
		\"foo\" myint : integer
		if(myint) {
			\"bar\" bar : integer
		}
	}
	");