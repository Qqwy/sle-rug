module Compile::CSS

/*
 * This modules creates a very simple CSS file.
 * that will help with the functionality of the form
 * and make it look nice on devices of various sizes.
 *
 * Note that no CSS frameworks have been used, 
 * which keeps the code small and self-contained.
 */

import AST;

import IO;

str compile(AForm f) 
  = readFile(|project://QL/src/Compile/Templates/style.css|);