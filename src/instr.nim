import strutils
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