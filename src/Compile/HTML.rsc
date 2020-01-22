module Compile::HTML

/*
 * This module compiles the QL file to a HTML document which references
 * the CSS and JavaScript that is also used during the compilation process.
 * 
 * Rascal's built-in 'lang::html5::DOM' was used to generate the HTML.
 */

import Compile::Helper;
import AST;
import Resolve;

import lang::html5::DOM; // see standard library

str compile(AForm f)
  = "\<!DOCTYPE html\>" + lang::html5::DOM::toString(compile(f, f.src));

HTML5Node compile(AForm f, loc filename)
	= html(
		htmlTemplateHead(filename[extension="css"].file),
		body(
			htmlTemplateForm(f),
			script(src(filename[extension="js"].file))
		)
	);

HTML5Node htmlTemplateHead(str cssloc)
	= head(
		meta(charset("utf-8")),
		link(\rel("stylesheet"), href(cssloc))
	);

HTML5Node htmlTemplateForm(AForm f)
	= form([
		name(f.name), 
		action("#"), 
		h1(f.name),
		*compile(f.questions)
	]);

list[HTML5Node] compile(list[AQuestion] questions)
  = [*compile(question) | question <- questions];

HTML5Node compile(simple_question(str qname, AId var, AType qtype))
  = div(
  		html5attr("data-ql-question", var.name),
  		label(\for(unescapedQuestionFieldName(var)), qname),
		input(\type(formInputType(qtype)), name(unescapedQuestionFieldName(var)), id(unescapedQuestionFieldName(var)))
  	);

HTML5Node compile(computed_question(str qname, AId var, AType qtype, _))
  = div(
  		html5attr("data-ql-question", var.name),
  		label(\for(unescapedQuestionFieldName(var)), qname),
		input(\type(formInputType(qtype)), name(unescapedQuestionFieldName(var)), id(unescapedQuestionFieldName(var)), disabled("disabled"))
  	);

list[HTML5Node] compile(conditional(\if(AExpr condition, list[AQuestion] questions)))
	= [div([
		html5attr("data-ql-if", unescapedConditionFieldName(condition)),
		*compile(questions)]
	)];

list[HTML5Node] compile(conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= [
		div([
			html5attr("data-ql-if", conditionFieldName(condition)),
			*compile(if_questions)]
		),
		div([
			html5attr("data-ql-else", conditionFieldName(condition)),
			*compile(else_questions)]
		)
	];

str formInputType(boolean()) = "checkbox";
str formInputType(integer()) = "number";
str formInputType(string())  = "text";