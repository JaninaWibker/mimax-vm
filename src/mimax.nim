import streams

import cli
import utils
import parser
import instr
import main

var options = parseOptions()

echo options

var program: Prgm

# if bin is set or disassemble is set then parse the input as a binary file; otherwise as an assembly (plain text) file
if options.bin or options.disassemble:
  let stream = utils.read_binary_file(options.filepath, options.mima_version)
  program = bin_to_program(stream)
  stream.close()
else:
  let str = utils.read_text_file(options.filepath)
  program = parser.parse(str)


# execute the appropriate action using the parsed program
if options.compile:
  let stream = newFileStream(options.filepath & ".bin", fmWrite)
  program_to_bin(program, stream)
  stream.close()
elif options.debug:
  debug(program)
elif options.disassemble:
  echo disassemble(program)
else:
  execute_vm(program)
