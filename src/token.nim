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
    LDVR    = 0xe0 # how this all works:
    LDVR_RA = 0xe5 # The prefix 0xe is used for all of the LDVR/STVR instructions
    LDVR_SP = 0xe6 # Then a 0 for load or a 1 for store follows 
    LDVR_FP = 0xe7 # After that comes the addressing for the individual registers
    STVR    = 0xe8 # FP: 111, RA: 101, SP: 110
    STVR_RA = 0xed # These are all derived from their values inside the registers enum
    STVR_SP = 0xee # There are also two special "opcodes" which just represent all
    STVR_FP = 0xef # of the LDVR/STVR opcodes as a group
    HALT = 0xf0
    NOT  = 0xf1
    RAR  = 0xf2
    RET  = 0xf3
    LDSP = 0xf4
    STSP = 0xf5
    LDFP = 0xf6
    STFP = 0xf7
    LDRA = 0xf8
    STRA = 0xf9

type
  registers* = enum
    # skipping some values for future additions
    A   = 0x00
    # skipping 0x01, 0x02
    IR  = 0x03
    IAR = 0x04 # usable with LDVR/STVR; 0100 # TODO: should it; slides don't say anything?
    RA  = 0x05 # usable with LDVR/STVR; 0101
    # skipping 0x06
    SP  = 0x06 # usable with LDVR/STVR; 0110
    FP  = 0x07 # usable with LDVR/STVR; 1111
    # skipping 0x09, 0x0a
    SAR = 0x0a
    SDR = 0x0b
    # skipping 0x0c
    X   = 0x0d
    Y   = 0x0e
    ONE = 0x0f


type
  TokenType* = enum
    OPCODE
    REGISTER
    INTEGER
    WS
    IDENTIFIER
    COLON
    LPAREN
    RPAREN
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
