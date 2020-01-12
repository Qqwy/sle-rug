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
			link(\rel("stylesheet"), href(cssloc))
		), 
		body(
			form(
				name(f.name), 
				action("#"), 
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
  	label(\for(var.name), qname),
	input(\type(ATypeToHTMLInputType(qtype)), name(var.name))
  	);

HTML5Node htmlCompile(computed_question(str qname, AId var, AType qtype, _))
  = div(
  	html5attr("data-ql-question", var.name),
  	label(\for(var.name), qname),
	input(\type(ATypeToHTMLInputType(qtype)), name(var.name), html5attr("disabled", "disabled"))
  	);

HTML5Node htmlCompile(conditional(\if(AExpr condition, list[AQuestion] questions)))
	= div(
		html5attr("data-ql-if", unescapedConditionFieldName(condition)),
		htmlCompile(questions)
	);
HTML5Node htmlCompile(conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= div(
		div(
			html5attr("data-ql-if", unescapedConditionFieldName(condition)),
			htmlCompile(if_questions)
		),
		div(
			html5attr("data-ql-else", unescapedConditionFieldName(condition)),
			htmlCompile(else_questions)
		)
	);

HTML5Node htmlCompile(AQuestion q) = span("TODO");

str ATypeToHTMLInputType(boolean()) = "checkbox";
str ATypeToHTMLInputType(integer()) = "number";
str ATypeToHTMLInputType(string()) = "text";


str form2js(AForm f) {
  return "<readFile(|project://QL/src/CompileSnippets/javascript.js|)>
  		 '
  		 'function initQuestions() {
  		 '	var window.ql_questions = <form2jsInitialValues(f)>;
  		 '}
  		 '
  		 'function update(ql_questions) {
  		 '	<form2jsUpdate(f)>
  		 '	return ql_questions;
  		 '}
  		 '";
}

str form2jsUpdate(AForm f) 
	= form2jsUpdate(f.questions);

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

list[str] form2jsInitialQuestions(AForm f) {
	map[AId name, AType \type] env = 
	  (label: qtype | /simple_question(_, AId label, AType qtype)      := f)
	+ (label: qtype | /computed_question(_, AId label, AType qtype, _) := f)
	;
	println(env);
	inits = ["<questionFieldName(label)> : <jsDefaultValue(env[label])>" | label <- env];
	return inits;
}

// Transforms all conditionals into string keys representing that conditional.
// Not beautiful (it would be nicer if we'd use a pretty printer), but it works.
list[str] form2jsInitialConditionals(AForm f) {
	map[AExpr condition, AType \type] env = 
	  (condition: boolean() | /\if(AExpr condition, _)      := f)
	+ (condition: boolean() | /ifelse(AExpr condition, _, _) := f)
	;

	inits = ["<conditionFieldName(condition)> : <jsDefaultValue(env[condition])>" | condition <- env];
	return inits;
}

str questionFieldName(AId label)
	= "\"question_<label.name>\"" ;
	
str conditionFieldName(AExpr condition)
	= "\"<unescapedConditionFieldName(condition)>";

str unescapedConditionFieldName(AExpr condition)
	= "condition_(<escape(toJSExpr(condition), ("\"": "\\\""))>)";


str jsDefaultValue(boolean()) = "false";
str jsDefaultValue(integer()) = "0";
str jsDefaultValue(string()) = "\"\"";


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



str toJSLit(lit_integer(int int_val)) = "<int_val>";
str toJSLit(lit_boolean(bool bool_val)) = "<bool_val>";
str toJSLit(lit_string(str str_val)) = "\"<str_val>\"";



str form2css(AForm f) {
return "
	input {
	    margin: 1em;
	}
	
	label {
	    margin-top: 1.5em;
	}
	
	
	.hidden {
	    display: none;
	}";
}

str jsPreamble() {
	return "";
}

// Compiles a QL form from an input string,
// and writes the output to temporary files.
void compileFromString(str inputForm, loc src) {
	t = parse(#start[Form], inputForm);
	if (start[Form] pt := t) {
		
        AForm ast = cst2ast(pt);
        ast.src = src;
        //println(ast.src);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        if (msgs == {}) {
          return compile(ast);
        }
        throw msgs;
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


test bool compileExample() {
	compileFromString(readFile(|project://QL/examples/simple_example.myql|), |project://QL/examples/simple_example.myql|);
	return true;
}

