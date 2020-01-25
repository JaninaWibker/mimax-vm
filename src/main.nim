import strutils

import cli
import utils
import lexer

var options = parseOptions()

if options.bin:
  # let stream = utils.read_binary_file(options.filepath)
  echo "not yet supported"
  quit(1)
elif options.compile:
  echo "not yet supported"
  quit(1)
elif options.debug:
  echo "not yet supported"
  quit(1)
elif options.disassemble:
  # let str = utils.read_text_file(options.filepath)
  echo "not yet supported"
  quit(1)
else:
  let str = utils.read_text_file(options.filepath)

  lex.source = splitLines(str)
  while not isAtEnd(lex):
    echo lex.next()


echo options