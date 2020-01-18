module Compile::HTML

import AST;
import Resolve;
import lang::html5::DOM; // see standard library
import Compile::Javascript; // We use some Javascript-compilation-based names in our HTML attribute values.

str compile(AForm f, loc filename)
  = "\<!DOCTYPE html\>" + lang::html5::DOM::toString(htmlCompile(f, f.src));

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
			form([
				name(f.name), 
				action("#"), 
				h1(f.name),
				*htmlCompile(f.questions)
				]
			),
			script(src(jsloc))
		)
	);
	return res;
}


list[HTML5Node] htmlCompile(list[AQuestion] questions)
  = [*htmlCompile(question) | question <- questions];

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

list[HTML5Node] htmlCompile(conditional(\if(AExpr condition, list[AQuestion] questions)))
	= [div([
		html5attr("data-ql-if", htmlEscapedConditionFieldName(condition)),
		*htmlCompile(questions)]
	)];

list[HTML5Node] htmlCompile(conditional(\ifelse(AExpr condition, list[AQuestion] if_questions, list[AQuestion] else_questions)))
	= [
		div([
			html5attr("data-ql-if", htmlEscapedConditionFieldName(condition)),
			*htmlCompile(if_questions)]
		),
		div([
			html5attr("data-ql-else", htmlEscapedConditionFieldName(condition)),
			*htmlCompile(else_questions)]
		)
	];

str ATypeToHTMLInputType(boolean()) = "checkbox";
str ATypeToHTMLInputType(integer()) = "number";
str ATypeToHTMLInputType(string())  = "text";