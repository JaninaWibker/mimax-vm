import tables
import streams
import strutils
import strformat
from token import opcodes
from instr import text_repr

import instr
import vm
from cli import AnsiColor

proc make_vm*(program: Prgm): VMState =
  var labels = initTable[string, uint]()

  var buf: seq[array[3, uint8]]
  var mem: array[1024, array[3, uint8]]

  for stmt in program.lines:
    if stmt.label != "":
      labels[stmt.label] = stmt.line

  for stmt in program.lines:
    buf.add(bin_repr(stmt.instr, labels))

  return makeVM(buf, mem)

proc execute_vm*(program: Prgm) =

  var vmstate = make_vm(program)

  echo fmt"A: {AnsiColor.f_blue}{vmstate.a}{AnsiColor.reset} SP: {AnsiColor.f_blue}{vmstate.sp}{AnsiColor.reset} IAR: {AnsiColor.f_blue}{vmstate.iar}{AnsiColor.reset} (initial state)"

  while vmstate.running:
    vmstate = vmstate.execute()
    echo fmt"A: {AnsiColor.f_blue}{vmstate.a}{AnsiColor.reset} SP: {AnsiColor.f_blue}{vmstate.sp}{AnsiColor.reset} IAR: {AnsiColor.f_blue}{vmstate.iar}{AnsiColor.reset}"

  echo fmt"{AnsiColor.f_red}halted{AnsiColor.reset}"


proc compile*(program: Prgm): iterator(): uint8 =
  result = iterator(): uint8 =
    var labels = init_table[string, uint]()

    for stmt in program.lines:
      if stmt.label != "":
        labels[stmt.label] = stmt.line

    for stmt in program.lines:
      let bin = bin_repr(stmt.instr, labels)
      yield bin[0]
      yield bin[1]
      yield bin[2]


proc bin_to_program*(stream: FileStream): Prgm =

  var instr: array[3, uint8]
  var i = 0
  var line: uint = 0
  var program = Prgm()

  while not(stream.at_end()):
    var curr: uint8
    discard stream.read_data(curr.addr, 1)
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

proc program_to_bin*(program: Prgm, stream: FileStream) =
  
  # write mima(x) header
  stream.write("mimax\0")

  let it = compile(program)

  for bit in it():
    stream.write(bit) 

proc disassemble*(program: Prgm, addresses: bool, color: bool, current_position: int): string = 
  result = ""

  var used_labels = init_table[string, int]()

  # now search for mentioned labels
  for i in 0..program.lines.len-1:
    let stmt = program.lines[i]

    # add known labels to the list
    if stmt.label != "":
      used_labels[stmt.label] = i

    # add numeric labels to the list; if not numeric then it must be a known
    # label which has either already been added or will be added sooner or later
    if stmt.instr.opcode in [opcodes.JMP, opcodes.JMN, opcodes.CALL]:
      let value = stmt.instr.args[0].value
      try:
        used_labels[value] = parse_int(value)
      except:
        discard

  for name, address in used_labels:
    program.lines[address].label = name

  for i in 0..program.lines.len-1:
    let stmt = program.lines[i]

    # omit newline for the last iteration
    var nl = "\n"
    if i == program.lines.len-1:
      nl = ""

    # if current_position is set make the matching line bold (at least the address)
    var address_color = $AnsiColor.f_yellow
    if i == current_position:
      address_color = $AnsiColor.f_yellow & $AnsiColor.bold

    if color and addresses:
      result.add(fmt"{address_color}{i:#08X}{AnsiColor.reset} {colorful(stmt)}" & nl)
    elif color and not addresses:
      result.add(colorful(stmt) & nl)
    elif not color and addresses:
      result.add(fmt"{i:#08X} {$stmt}" & nl)
    elif not color and not addresses:
      result.add($stmt & nl)

  return result

proc disassemble*(program: Prgm, addresses: bool, color: bool): string =
  return disassemble(program, addresses, color, -1)

proc disassemble*(program: Prgm): string =
  return disassemble(program, true, true, -1)
