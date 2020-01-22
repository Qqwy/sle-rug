module Compile

/*
 * Implements a compiler for QL to HTML/CSS/Javascript
 */

import Compile::HTML;
import Compile::Javascript;
import Compile::CSS;
import AST;
import Resolve;

import IO;

void compile(AForm f) {
	str js = Compile::Javascript::compile(f);
  	writeFile(f.src[extension="js"].top, js);

	str css = Compile::CSS::compile(f);
  	writeFile(f.src[extension="css"].top, css);

  	str html = Compile::HTML::compile(f);
  	writeFile(f.src[extension="html"].top, html);
}

