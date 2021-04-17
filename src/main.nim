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


proc bin_to_program(stream: FileStream): Prgm =

  var instr: array[3, uint8]
  var i = 0
  var line: uint = 0
  var program = Prgm()

  while not(stream.atEnd()):
    var curr: uint8
    discard stream.readData(curr.addr, 1)
    instr[i] = curr
    i = (i + 1) mod 3
    if i == 0:
      
      # construct statement and add to program
      var stmt = Stmt()
      var instr = text_repr(instr)
      stmt.line = line
      stmt.instr = instr
      # stmt.label would be good maybe, but don't know how this would be done tbh
      program.lines.add(stmt)
      line = line + 1
      
  return program


proc compile(program: Prgm): iterator(): uint8 =
  result = iterator(): uint8 =
    var labels = initTable[string, uint]()

    for stmt in program.lines:
      if stmt.label != "":
        labels[stmt.label] = stmt.line

    for stmt in program.lines:
      let bin = bin_repr(stmt.instr, labels)
      yield bin[0]
      yield bin[1]
      yield bin[2]


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

  let program = bin_to_program(stream)

  echo program

  stream.close()

  execute_vm(program)
  
elif options.compile:
  let str = utils.read_text_file(options.filepath)

  let program = parser.parse(str)
  let stream = newFileStream(options.filepath & ".bin", fmWrite)

  let it = compile(program)

  # write mima(x) header
  stream.write("mimax\0")

  for bit in it():
    stream.write(bit)

  stream.close()

elif options.debug:
  # TODO: this should be a debugger which allows inspecting values, setting breakpoints and stepping through code
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