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
      let num = parseInt(instr.args[0].value)
      bin[0] = cast[uint8](ord(instr.opcode)) # this only sets the upper 4 bits as the lower 4 bits are always 0
      bin[0] += bitand(cast[uint8](num shr 16), 0x0f)
      bin[1] = cast[uint8](num shr 8)
      bin[2] = cast[uint8](num)

    # non-extended opcodes followed by label
    of opcodes.JMP, opcodes.JMN, opcodes.CALL:
      
      bin[0] = cast[uint8](ord(instr.opcode)) # this only sets the upper 4 bits as the lower 4 bits are always 0
      echo instr.args[0].kind
      echo instr.args[0].value
      var label: uint
      
      if instr.args[0].kind == ArgType.INTEGER:
        label = parseUInt(instr.args[0].value)
      else:
        label = labels[instr.args[0].value]

      bin[0] += bitand(cast[uint8](label shr 16), 0x0f)
      bin[1] = cast[uint8](label shr 8)
      bin[2] = cast[uint8](label)

    # extended opcodes not followed by arguments
    of opcodes.RET, opcodes.HALT, opcodes.NOT, opcodes.RAR,
       opcodes.LDSP, opcodes.STSP, opcodes.LDFP, opcodes.STFP,
       opcodes.LDRA, opcodes.STRA:
      bin[0] = cast[uint8](ord(instr.opcode)) # this sets the whole 8 bits as the opcode already includes the extended-opcodes prefix
      bin[1] = 0
      bin[2] = 0
    of opcodes.LDVR, opcodes.STVR:
      let offset: uint16 = cast[uint16](parseInt(instr.args[0].value))
      let register: registers = parseEnum[registers](instr.args[1].value.toUpper)

      bin[0] = cast[uint8](instr.opcode) + cast[uint8](bitand(ord(register), 7))
      bin[1] = cast[uint8](offset shr 8)
      bin[2] = cast[uint8](offset)

    else:
      echo "error, invalid instruction"
    
  return bin

proc text_repr*(instr: array[3, uint8]): Instr =
  var rtn = Instr()
  # echo instr
  case bitand(instr[0], 0xf0):
    of ord(opcodes.LDVR):

      var value = cast[int](cast[uint](instr[1]) shl 8 + cast[uint](instr[2]))

      const modulo = 1 shl 16
      const max_value = (1 shl 15) - 1

      if value > max_value: value -= modulo

      rtn.args.add(Arg(kind: ArgType.INTEGER, value: $value))
      case instr[0]:
        of ord(opcodes.LDVR_FP):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.FP))
          rtn.opcode = opcodes.LDVR
        of ord(opcodes.LDVR_RA):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.RA))
          rtn.opcode = opcodes.LDVR
        of ord(opcodes.LDVR_SP):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.SP))
          rtn.opcode = opcodes.LDVR
        of ord(opcodes.STVR_FP):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.FP))
          rtn.opcode = opcodes.STVR
        of ord(opcodes.STVR_RA):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.RA))
          rtn.opcode = opcodes.STVR
        of ord(opcodes.STVR_SP):
          rtn.args.add(Arg(kind: ArgType.REGISTER, value: $registers.SP))
          rtn.opcode = opcodes.STVR
        else:
          echo "error extended-opcodes-2"
    of ord(opcodes.HALT):
      case instr[0]:
        of ord(opcodes.HALT): rtn.opcode = opcodes.HALT
        of ord(opcodes.NOT):  rtn.opcode = opcodes.NOT
        of ord(opcodes.RAR):  rtn.opcode = opcodes.RAR
        of ord(opcodes.RET):  rtn.opcode = opcodes.RET
        of ord(opcodes.LDSP): rtn.opcode = opcodes.LDSP
        of ord(opcodes.STSP): rtn.opcode = opcodes.STSP
        of ord(opcodes.LDFP): rtn.opcode = opcodes.LDFP
        of ord(opcodes.STFP): rtn.opcode = opcodes.STFP
        of ord(opcodes.LDRA): rtn.opcode = opcodes.LDRA
        of ord(opcodes.STRA): rtn.opcode = opcodes.STRA
        else:
          echo "error extended-opcodes-1"
    else:
      rtn.opcode = opcodes(bitand(instr[0], 0xf0))

      var value = cast[int]((cast[uint](bitand(instr[0], 0x0f)) shl 16) + (cast[uint](instr[1]) shl 8) + (instr[2]))

      const modulo = 1 shl 20
      const max_value = (1 shl 19) - 1

      if value > max_value: value -= modulo

      rtn.args.add(Arg(kind: ArgType.INTEGER, value: $value))
  return rtn