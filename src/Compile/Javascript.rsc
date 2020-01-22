module Compile::Javascript

/*
 * This module compiles the form down to a JavaScript file.
 * This is done by filling in two pieces of dynamic code
 * in an otherwise static JavaScript file (see 'Compile/Templates/javascript.js'):
 * - the initial runtime environment where we keep track of the values of questions/conditionals.
 * - the body of the 'update' function where conditionals and computed questions are re-evaluated
 *   after one of the form fields was altered.
 * 
 * Note that no external JavaScript-frameworks or -libraries have been used,
 * which keeps the code small and self-contained.
 * 
 * Compatible with all modern browsers and IE9 and above.
 */

import Compile::Helper;
import AST;
import Resolve;

import IO;
import List;
import String;

str compile(AForm f) {
	str template = readFile(|project://QL/src/Compile/Templates/javascript.js|);
	template = replaceFirst(template, "\"{{initialEnv}}\"", initialEnv(f));
	template = replaceFirst(template, "\"{{update}}\"", update(f));
	return template;
}

str initialEnv(AForm f)
  = "
	'function initQuestions() {
	'	ql_questions = <initialValues(f)>;
	'}
	'";
	
str initialValues(AForm f) {
	question_values = initialQuestions(f);
	conditional_values = initialConditionals(f);
	str combined = intercalate(",\n", question_values + conditional_values);
	return"{\n<combined>\n}";
}
// Transforms all simple and computed questions into string keys representing that question,
// filling it with the default value.
list[str] initialQuestions(AForm f) {
	questions = initialQuestionsMap(f);
	return ["<questionFieldName(label)> : <defaultValue(questions[label])>" | label <- questions];
}

map[AId name, AType \type] initialQuestionsMap(AForm f)
  = (label: qtype | /simple_question(_, AId label, AType qtype)      := f)
  + (label: qtype | /computed_question(_, AId label, AType qtype, _) := f)
  ;

// Transforms all conditionals into string keys representing that conditional, filling it with the default value.
list[str] initialConditionals(AForm f) {
	conditionals = initialConditionalsMap(f);
	return ["<conditionFieldName(conditional)> : <defaultValue(conditionals[conditional])>" | conditional <- conditionals];
}

map[AExpr condition, AType \type] initialConditionalsMap(AForm f) 
  = (condition: boolean() | /\if(AExpr condition, _)      := f)
  + (condition: boolean() | /ifelse(AExpr condition, _, _) := f)
  ;


str defaultValue(boolean()) = "false";
str defaultValue(integer()) = "0";
str defaultValue(string()) = "\"\"";


str update(AForm f) 
  = "
	'function update(ql_questions) {
	'	<update(f.questions)>
	'	return ql_questions;
	'}
	";

str update(list[AQuestion] questions)
  = ("" | it + update(question) | question <- questions);

str update(block(List[AQuestion]questions))
	= update(questions);

// Simple questions do not need to be updated, they are updated only when someone enters something.
str update(\simple_question(_, AId label, _))
	= "";
	
str update(\computed_question(_, AId label, _, AExpr expr))
	= "ql_questions[<questionFieldName(label)>] = <toJSExpr(expr)>;\n";

str update(\conditional(\if(AExpr condition, list[AQuestion] questions)))
	= "
	'ql_questions[<conditionFieldName(condition)>] = <toJSExpr(condition)>;
	'if(ql_questions[<conditionFieldName(condition)>]) {
	'	<update(questions)>}
	";

str update(\conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= "
	'ql_questions[<conditionFieldName(condition)>] = <toJSExpr(condition)>;
	'if(ql_questions[<conditionFieldName(condition)>]) {
	'	<update(if_questions)>
	'} else {
	'	<update(else_questions)>}
	";


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