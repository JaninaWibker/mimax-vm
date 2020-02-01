import strutils
import bitops
import tables

import token

type
  ArgType* = enum
    INTEGER
    LABEL
    REGISTER

type
  Arg* = ref object
    kind*: ArgType
    value*: string

type
  Instr* = ref object
    opcode*: opcodes
    args*: seq[Arg]

type
  Stmt* = ref object
    label*: string
    instr*: Instr
    line*: uint

type
  Prgm* = ref object
    lines*: seq[Stmt]

proc `$`*(arg: Arg): string =
  case arg.kind:
    of INTEGER:   return arg.value
    of LABEL:     return "%" & arg.value
    of REGISTER:  return "(" & arg.value & ")"

proc `$`*(instr: Instr): string =
  var str = $instr.opcode
  for arg in instr.args:
    str = str & " " & $arg
  return str

proc `$`*(stmt: Stmt): string =
  if stmt.label.len != 0:
    return "$1:\t$2" % [stmt.label, $stmt.instr]
  else:
    return "\t$1" % [$stmt.instr]

proc `$`*(prgm: Prgm): string =
  var str = ""
  for line in prgm.lines:
    str = str & $line & "\n"
  return str

proc bin_repr*(instr: Instr, labels: Table[string, uint]): array[3, uint8] =
  var bin: array[3, uint8]
  case instr.opcode
    # non-extended opcodes followed by number
    of opcodes.LDC, opcodes.LDV, opcodes.STV, opcodes.ADD,
       opcodes.AND, opcodes.OR,  opcodes.XOR, opcodes.EQL,
       opcodes.LDIV, opcodes.STIV, opcodes.ADC:
      var num = parseInt(instr.args[0].value)
      bin[0] = cast[uint8](ord(instr.opcode)) # this only sets the upper 4 bits as the lower 4 bits are always 0

      bin[0] += bitand(cast[uint8](num shr 16), 0x7f)
      bin[1] = cast[uint8](num shr 8)
      bin[2] = cast[uint8](num)

    # non-extended opcodes followed by label
    of opcodes.JMP, opcodes.JMN, opcodes.CALL:
      
      bin[0] = cast[uint8](ord(instr.opcode)) # this only sets the upper 4 bits as the lower 4 bits are always 0
      var label: uint = labels[instr.args[0].value]
      bin[0] += bitand(cast[uint8](label shr 16), 0x7f)
      bin[1] = cast[uint8](label shr 8)
      bin[2] = cast[uint8](label)

    # extended opcodes not followed by arguments
    of opcodes.RET, opcodes.HALT, opcodes.NOT, opcodes.RAR,
       opcodes.LDSP, opcodes.STSP:
      bin[0] = cast[uint8](ord(instr.opcode)) # this sets the whole 8 bits as the opcode already includes the extended-opcodes prefix
      bin[1] = 0
      bin[2] = 0
    # unknown as of right now
    of opcodes.LDVR, opcodes.STVR:
      bin[0] = 0
      bin[1] = 0
      bin[2] = 0
      discard

  return bin