module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List; // intercalate
import String; // escape

import Compile::HTML;
import Compile::Javascript;
import Compile::CSS;

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
	str js = Compile::Javascript::compile(f);
  	writeFile(f.src[extension="js"].top, js);

	str css = Compile::CSS::compile(f);
  	writeFile(f.src[extension="css"].top, css);

  	str html = Compile::HTML::compile(f, f.src);
  	writeFile(f.src[extension="html"].top, html);
}

