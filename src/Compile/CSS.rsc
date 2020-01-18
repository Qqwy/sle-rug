module Compile::CSS

import AST;
import IO;

str compile(AForm f) 
  = readFile(|project://QL/src/Compile/Templates/style.css|);