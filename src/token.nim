import strutils

type
  opcodes* = enum
    LDC  = 0x00
    LDV  = 0x10
    STV  = 0x20
    ADD  = 0x30
    AND  = 0x40
    OR   = 0x50
    XOR  = 0x60
    EQL  = 0x70
    JMP  = 0x80
    JMN  = 0x90
    LDIV = 0xa0
    STIV = 0xb0
    CALL = 0xc0
    ADC  = 0xd0
    LDVR = 0xe0 # how will ldvr <value> (<register>) be implemented?
    STVR = 0xe1 # how will stbr <value> (<register>) be implemented?
    HALT = 0xf0
    NOT  = 0xf1
    RAR  = 0xf2
    RET  = 0xf3
    LDSP = 0xf4
    STSP = 0xf5

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
  return "kind: $1, value: \"$2\", line: $3" % [$token.kind, token.value, $(token.line+1)]
