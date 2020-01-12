module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List; // intercalate
import String; // escape

import Syntax; // For tests only.
import ParseTree; // For tests only.
import CST2AST; // For tests only.
import Check; // For tests only.

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
	str js = form2js(f);
	println(js);
  	writeFile(f.src[extension="js"].top, js);

	str css = form2css(f);
	println(css);
  	writeFile(f.src[extension="css"].top, css);

  	str html = "\<!DOCTYPE html\>" + lang::html5::DOM::toString(htmlCompile(f, f.src));
  	println(html);
  	writeFile(f.src[extension="html"].top, html);
}

HTML5Node htmlCompile(AForm f, loc filename) {
	str cssloc = filename[extension="css"].file;
	str jsloc = filename[extension="js"].file;
	HTML5Node res = 
	html(
		head(
			meta(charset("utf-8")),
			link(\rel("stylesheet"), href(cssloc))
		), 
		body(
			form(
				name(f.name), 
				action("#"), 
				h1(f.name),
				htmlCompile(f.questions)
			),
			script(src(jsloc))
		)
	);
	//println(res);
	return res;
}


HTML5Node htmlCompile(list[AQuestion] questions)
  = div([htmlCompile(question)  | question <- questions]);

// TODO: Disambugate between different types of questions here.
HTML5Node htmlCompile(simple_question(str qname, AId var, AType qtype))
  = div(
  	html5attr("data-ql-question", var.name),
  	label(\for(unescapedQuestionFieldName(var)), qname),
	input(\type(ATypeToHTMLInputType(qtype)), name(unescapedQuestionFieldName(var)))
  	);

HTML5Node htmlCompile(computed_question(str qname, AId var, AType qtype, _))
  = div(
  	html5attr("data-ql-question", var.name),
  	label(\for(unescapedQuestionFieldName(var)), qname),
	input(\type(ATypeToHTMLInputType(qtype)), name(unescapedQuestionFieldName(var)), disabled("disabled"))
  	);

HTML5Node htmlCompile(conditional(\if(AExpr condition, list[AQuestion] questions)))
	= div(
		html5attr("data-ql-if", htmlEscapedConditionFieldName(condition)),
		htmlCompile(questions)
	);
HTML5Node htmlCompile(conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= div(
		div(
			html5attr("data-ql-if", htmlEscapedConditionFieldName(condition)),
			htmlCompile(if_questions)
		),
		div(
			html5attr("data-ql-else", htmlEscapedConditionFieldName(condition)),
			htmlCompile(else_questions)
		)
	);

HTML5Node htmlCompile(AQuestion q) = span("TODO");

str ATypeToHTMLInputType(boolean()) = "checkbox";
str ATypeToHTMLInputType(integer()) = "number";
str ATypeToHTMLInputType(string()) = "text";


str form2js(AForm f) {
	str template = readFile(|project://QL/src/CompileSnippets/javascript.js|);
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
	map[AId name, AType \type] env = 
	  (label: qtype | /simple_question(_, AId label, AType qtype)      := f)
	+ (label: qtype | /computed_question(_, AId label, AType qtype, _) := f)
	;
	println(env);
	inits = ["<questionFieldName(label)> : <jsDefaultValue(env[label])>" | label <- env];
	return inits;
}

// Transforms all conditionals into string keys representing that conditional, filling it with the default value.
list[str] form2jsInitialConditionals(AForm f) {
	map[AExpr condition, AType \type] env = 
	  (condition: boolean() | /\if(AExpr condition, _)      := f)
	+ (condition: boolean() | /ifelse(AExpr condition, _, _) := f)
	;

	inits = ["<conditionFieldName(condition)> : <jsDefaultValue(env[condition])>" | condition <- env];
	return inits;
}
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
str toJSLit(lit_integer(int int_val)) = "<int_val>";
str toJSLit(lit_boolean(bool bool_val)) = "<bool_val>";
str toJSLit(lit_string(str str_val)) = "\"<escape(str_val, ("\"": "\\\""))>\"";


// The following CSS is mobile-friendly, since it is viewport-size responsive.
str form2css(AForm f) {
return "
	form {
		margin: auto;
		max-width: 60em;
		padding: 0em 1em;
		font-size: 1.1em;
	}
	
	input {
		display: inline-block;
	    max-width: 30em;
	    width: 45%;
	}
	
	label {
		display: inline-block;
	    margin-top: 1.5em;
	    max-width: 30em;
	    width: 45%;
	}
	
	
	.hidden {
	    display: none;
	}";
}


// Compiles a QL form from an input string,
// and writes the output to temporary files.
// Allows you to pass in a source location manually, 
// which allows us to use small strings as well as files.
void compileFromString(str inputForm, loc src) {
	t = parse(#start[Form], inputForm);
	if (start[Form] pt := t) {
		
        AForm ast = cst2ast(pt);
        ast.src = src;
        //println(ast.src);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        //if (msgs == {}) {
          return compile(ast);
        //}
        //throw msgs;
      }
  throw {error("Not a form", t@\loc)};
}

// This test succeeds as long as no exceptions occur during compilation.
test bool simpleCompileTest() {
	str form = "form a {
		\"foo\" foo : integer
		if(foo \> 20) {
			\"bar\" bar : integer = foo + 33
		}
	}
	";
	compileFromString(form, |tmp:///test.myql|);
	return true;
}

/*
 * Immediately compile the examples, to make sure we can indeed compile them without compile-time errors.
 */

test bool compileSimpleExample() {
	compileFromString(readFile(|project://QL/examples/simple_example.myql|), |project://QL/examples/simple_example.myql|);
	return true;
}


test bool compileTax() {
	compileFromString(readFile(|project://QL/examples/tax.myql|), |project://QL/examples/tax.myql|);
	return true;
}

test bool compileBinary() {
	compileFromString(readFile(|project://QL/examples/binary.myql|), |project://QL/examples/binary.myql|);
	return true;
}

test bool compileEmpty() {
	compileFromString(readFile(|project://QL/examples/empty.myql|), |project://QL/examples/empty.myql|);
	return true;
}

