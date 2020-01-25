import strutils

import token
import lexer
import instr

# the state is always what kind of token is expected to come next (start and error are the exception to that)
type
  ParserState = enum
    START
    COLON
    OPCODE
    ARGUMENTS
    IDENTIFIER # this is for jumping to a label via %label, this is not for declaring labels
    REGISTER
    RPARAN
    ERROR

proc parse*(input: string) =
  lex.source = splitLines(input)

  var state = START
  var program = Prgm()

  while not isAtEnd(lex):
    echo "state: ", $state

    var token = lex.next()
    echo token

    if token.kind == TokenType.WS: continue

    case state
      of START:
        if token.kind == TokenType.IDENTIFIER:
          state = COLON
        elif token.kind == TokenType.OPCODE:
          # TODO: save this opcode somehow
          state = ARGUMENTS
        else:
          # error
          echo "error"
          state = ERROR

      of COLON:
        if token.kind == TokenType.COLON:
          state = OPCODE
        else:
          # error
          echo "error"
          state = ERROR

      of OPCODE:
        if token.kind == TokenType.OPCODE:
          state = ARGUMENTS
        else:
          # error
          echo "error"
          state = ERROR

      of IDENTIFIER:
        if token.kind == TokenType.IDENTIFIER:
          state = ARGUMENTS
        else:
          # error
          echo "error"
          state = ERROR

      of REGISTER:
        if token.kind == TokenType.REGISTER:
          state = RPARAN
        else:
          # error
          echo "error"
          state = ERROR

      
      of ERROR:
        echo "error in line ", lex.line, " at position ", lex.current 