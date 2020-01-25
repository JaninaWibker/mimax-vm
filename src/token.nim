import strutils

type
  opcodes* = enum
    LDC
    LDV
    STV
    LDIV
    STIV
    ADD
    AND
    OR
    XOR
    NOT
    RAR
    EQL
    JMP
    JMN
    HALT
    CALL
    RET
    LDVR
    STVR
    LDSP
    STSP
    LDFP
    STFP
    LDRA
    STRA
    ADC

type
  registers* = enum
    IR
    RA
    IAR
    A
    ONE
    SP
    FP
    SAR
    SDR
    X
    Y

type
  TokenType* = enum
    OPCODE
    REGISTER
    INTEGER
    WS
    IDENTIFIER
    COLON
    LPARAN
    RPARAN
    PERCENTAGE
    EOF
    UNKNOWN

type
  Token* = object
    kind*: TokenType
    line*: int
    value*: string

proc `$`*(token: Token): string =
  return "kind: $1, value: \"$2\", line: $3" % [$token.kind, token.value, $token.line]
