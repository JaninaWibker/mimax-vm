import cli
import utils
import parser
import instr

var options = parseOptions()

echo options

if options.bin:
  let stream = utils.read_binary_file(options.filepath)
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

  var program = parser.parse(str)
  echo program