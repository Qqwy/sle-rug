module Test::CST2AST

import Test::Helper;

import Syntax;

test bool parsesVariable()
	= ref(AExpr::id("something")) := parse2ast(#Expr, "something");

test bool parsesPlus(int lhs, int rhs)
	= plus(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> + <rhs>");

test bool parsesMinus(int lhs, int rhs)
	= minus(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> - <rhs>");

test bool parsesMult(int lhs, int rhs)
	= mult(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> * <rhs>");

test bool parsesSimpleQuestion()
	= simple_question("foo", AExpr::id("val"), integer()) := parse2ast(#Question, "\"foo\" val : integer");

test bool parsesComputedQuestion(int val)
	= computed_question("foo", AExpr::id("varname"), integer(), AExpr::lit(lit_integer(val))) := parse2ast(#Question, "\"foo\" varname : integer = <val>");

test bool parsesEmptyBlock()
	= block(_) := parse2ast(#Question, "{}");

test bool parsesNestedBlock()
	= block([block([])]) := parse2ast(#Question, "{{}}");

test bool parsesIf()
	= \if(_, _) := parse2ast(#Conditional, "if (1) {\"bar\" bar : integer = 33}");

test bool parsesIfElse()
	= \ifelse(_, _, _) := parse2ast(#Conditional, "if (1) {} else {\"bar\" bar : integer = 33}");

test bool parsesForm()
	= form(_, _) := parse2ast(#Form, "form foo { \"x\" x : integer = 33}");
	