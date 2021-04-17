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

  var vmstate = makeVM(buf, mem)

  echo "initial: A:", vmstate.a, " SP: ", vmstate.sp, " IAR: ", vmstate.iar

  while vmstate.running:
    vmstate = vmstate.execute()
    echo "A:", vmstate.a, " SP: ", vmstate.sp, " IAR: ", vmstate.iar

  echo "halted"


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


proc disassemble(program: Prgm): string =
  # TODO: can do a lot of improvements here like prettier output, generating labels based on what things are being CALL'ed, ...
  result = ""

  for stmt in program.lines:
    result.add($stmt & '\n')


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

  # write mima(x) header
  stream.write("mimax\0")

  let it = compile(program)

  for bit in it():
    stream.write(bit)

  stream.close()
elif options.debug:
  # TODO: this should be a debugger which allows inspecting values, setting breakpoints and stepping through code
  # * this is how it should work:
  # * command prompt where you can enter commands (shortened to single letters mostly; long version probably not even supported with arguments)
  # * displaying information & general things
  # * - h                     : print help menu
  # * - i                     : print some information (this probably takes a lot of arguments)
  # * - it                    : toggle printing a lot of information on or off
  # * - d                     : disassemble (how much code is disassembled is still to be decided)
  # * stepping through code & breakpoints
  # * - s <n: int>            : step n steps forward (bypasses breakpoints)
  # * - s                     : alias of s 1
  # * - st <a: int>           : step to address a (bypasses breakpoints)
  # * - e                     : execute until a breakpoint is reached or the program HALTs
  # * - b <a: int>            : set a breakpoint at address a
  # * - br <n: int>           : set a breakpoint relative from the current location (+n)
  # * accessing values
  # * - m <a: int>            : read from memory at address a
  # * - r <r: reg>            : read from register r
  # * - m <a: int> = <v: int> : write v to memory at address a
  # * - r <r: reg> = <v: int> : write v to register r

  echo "not yet supported"
  quit(1)
elif options.disassemble:
  echo disassemble(program)
else:
  execute_vm(program)
