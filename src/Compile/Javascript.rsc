module Compile::Javascript

import AST;
import Resolve;
import IO;
import List;
import String;

str compile(AForm f) {
	str template = readFile(|project://QL/src/Compile/Templates/javascript.js|);
	template = replaceFirst(template, "\"{{initQuestions}}\"", form2jsInitQuestions(f));
	template = replaceFirst(template, "\"{{update}}\"", form2jsUpdate(f));
	return template;
}

str form2jsInitQuestions(AForm f)
  = "
	'function initQuestions() {
	'	ql_questions = <form2jsInitialValues(f)>;
	'}
	'";

str form2jsUpdate(AForm f) 
  = "
	'function update(ql_questions) {
	'	<form2jsUpdate(f.questions)>
	'	return ql_questions;
	'}
	";

str form2jsUpdate(list[AQuestion] questions)
  = ("" | it + form2jsUpdate(question) | question <- questions);

str form2jsUpdate(block(List[AQuestion]questions))
	= form2jsUpdate(questions);

// Simple questions do not need to be updated, they are updated only when someone enters something.
str form2jsUpdate(\simple_question(_, AId label, _))
	= "";
	
str form2jsUpdate(\computed_question(_, AId label, _, AExpr expr))
	= "ql_questions[<questionFieldName(label)>] = <toJSExpr(expr)>;\n";

str form2jsUpdate(\conditional(\if(AExpr condition, list[AQuestion] questions)))
	= "
	'ql_questions[<conditionFieldName(condition)>] = <toJSExpr(condition)>;
	'if(ql_questions[<conditionFieldName(condition)>]) {
	'	<form2jsUpdate(questions)>}
	";

str form2jsUpdate(\conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= "
	'ql_questions[<conditionFieldName(condition)>] = <toJSExpr(condition)>;
	'if(ql_questions[<conditionFieldName(condition)>]) {
	'	<form2jsUpdate(if_questions)>
	'} else {
	'	<form2jsUpdate(else_questions)>}
	";


str form2jsInitialValues(AForm f) {
	question_values = form2jsInitialQuestions(f);
	conditional_values = form2jsInitialConditionals(f);
	str combined = intercalate(",\n", question_values + conditional_values);
	return"{\n<combined>\n}";
}
// Transforms all simple and computed questions into string keys representing that question,
// filling it with the default value.
list[str] form2jsInitialQuestions(AForm f) {
	env = initialQuestionsEnv(f);
	return ["<questionFieldName(label)> : <jsDefaultValue(env[label])>" | label <- env];
}

map[AId name, AType \type] initialQuestionsEnv(AForm f)
  = (label: qtype | /simple_question(_, AId label, AType qtype)      := f)
  + (label: qtype | /computed_question(_, AId label, AType qtype, _) := f)
  ;

// Transforms all conditionals into string keys representing that conditional, filling it with the default value.
list[str] form2jsInitialConditionals(AForm f) {
	env = initialConditionalsEnv(f);
	return ["<conditionFieldName(condition)> : <jsDefaultValue(env[condition])>" | condition <- env];
}

map[AExpr condition, AType \type] initialConditionalsEnv(AForm f) 
  = (condition: boolean() | /\if(AExpr condition, _)      := f)
  + (condition: boolean() | /ifelse(AExpr condition, _, _) := f)
  ;

// We prepend all normal questions by `question_` and all conditionals by `condition_`
// to make sure we'll never have name clashes.
str questionFieldName(AId label)
	= "\"<unescapedQuestionFieldName(label)>\"";
	
str unescapedQuestionFieldName(AId label)
	= "question_<label.name>";
	
// We prepend all normal questions by `question_` and all conditionals by `condition_`
// to make sure we'll never have name clashes.
str conditionFieldName(AExpr condition)
	= "\'<unescapedConditionFieldName(condition)>\'";

str htmlEscapedConditionFieldName(AExpr condition)
	= "condition_(<escape(toJSExpr(condition), ("\"": "&quot;"))>)";

// A semi-hackish way of creating unique identifiers for the various conditionals:
// We turn the condition into its JS representation, and use a string version of this as identifier key in the runtime environment.
//
// Replaces `"` by `\"`, since the internals of the condition are used inside JS strings which are `"`-delimited.
str unescapedConditionFieldName(AExpr condition)
	= "condition_(<escape(toJSExpr(condition), ("\"": "\\\""))>)";

str jsDefaultValue(boolean()) = "false";
str jsDefaultValue(integer()) = "0";
str jsDefaultValue(string()) = "\"\"";

// Turns a QL AST expression into its JS runtime environment equivalent.
str toJSExpr(ref(AId id))					= "ql_questions[<questionFieldName(id)>]";
str toJSExpr(\lit(ALit literal))			= toJSLit(literal);
str toJSExpr(not(AExpr expr)) 				= "!<toJSExpr(expr)>";
str toJSExpr(mult(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> * <toJSExpr(rhs)>";
str toJSExpr(div(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> / <toJSExpr(rhs)>";
str toJSExpr(plus(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> + <toJSExpr(rhs)>";
str toJSExpr(minus(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> - <toJSExpr(rhs)>";
str toJSExpr(and(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> && <toJSExpr(rhs)>";
str toJSExpr(or(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> || <toJSExpr(rhs)>";
str toJSExpr(gt(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> \> <toJSExpr(rhs)>";
str toJSExpr(lt(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> \< <toJSExpr(rhs)>";
str toJSExpr(gte(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> \>= <toJSExpr(rhs)>";
str toJSExpr(lte(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> \<= <toJSExpr(rhs)>";
str toJSExpr(equal(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> === <toJSExpr(rhs)>";
str toJSExpr(not_equal(AExpr lhs, AExpr rhs)) 	= "<toJSExpr(lhs)> !== <toJSExpr(rhs)>";

// Literal strings receive an extra `"` surrounding them, and are escaped.
//
// !!Do note that proper JS/HTML special chars escaping does _not_ happen.
// It is _very_ possible to create usability and security problems by entering certain string literals.
str toJSLit(lit_integer(int int_val)) 	= "<int_val>";
str toJSLit(lit_boolean(bool bool_val)) = "<bool_val>";
str toJSLit(lit_string(str str_val)) 	= "\"<escape(str_val, ("\"": "\\\""))>\"";