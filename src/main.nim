import tables
import streams
import strutils

import cli
import utils
import parser
import instr
import vm

var options = parseOptions()

echo options

proc execute_vm(program: Prgm) =

  var labels = initTable[string, uint]()

  var buf: seq[array[3, uint8]]
  var mem: array[1024, array[3, uint8]]

  for stmt in program.lines:
    if stmt.label != "":
      labels[stmt.label] = stmt.line

  for stmt in program.lines:
    buf.add(bin_repr(stmt.instr, labels))

  let vmstate = makeVM(buf, mem)

  for i in 0..vmstate.buf.len-1:
    if not(vmstate.execute()): break

proc disassemble(stream: FileStream): string =

  var instr: array[3, uint8]
  var i = 0
  var rtn = ""

  while not(stream.atEnd()):
    var curr: uint8
    discard stream.readData(curr.addr, 1)
    instr[i] = curr
    i = (i + 1) mod 3
    if i == 0:
      rtn &= $text_repr(instr) & '\n'

  return rtn.strip()

if options.bin:
  let stream = utils.read_binary_file(options.filepath, options.mima_version)
  stream.close()
  echo "not yet supported"
  quit(1)
elif options.compile:
  echo "not yet supported"
  quit(1)
elif options.debug:
  echo "not yet supported"
  quit(1)
elif options.disassemble:
  let stream = utils.read_binary_file(options.filepath, options.mima_version)

  echo disassemble(stream)

  stream.close()
else:
  let str = utils.read_text_file(options.filepath)

  let program = parser.parse(str)

  echo program

  execute_vm(program)