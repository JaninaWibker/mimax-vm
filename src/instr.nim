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
    opcode: opcodes
    args: seq[Arg]

type
  Stmt* = ref object
    label*: string
    instr: Instr   

type
  Prgm* = ref object
    lines: seq[Stmt]

proc `$`*(arg: Arg): string =
  return "kind: $1, value: \"$2\"" % [$arg.kind, arg.value]

proc `$`*(instr: Instr): string =
  var str = $instr.opcode
  for arg in instr.args:
    str = str & " " & $arg
  return str

proc `$`*(stmt: Stmt): string =
  return "$1:\t$2" % [stmt.label, $stmt.instr]

proc `$`*(prgm: Prgm): string =
  var str = ""
  for line in prgm.lines:
    str = str & $line & "\n"
  return str