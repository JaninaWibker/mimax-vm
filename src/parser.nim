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

proc parse*(input: string): Prgm =
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

      of ARGUMENTS:
        if token.kind == TokenType.PERCENTAGE: # label
          state = IDENTIFIER
        elif token.kind == TokenType.LPARAN:
          state = REGISTER
        elif token.kind == TokenType.INTEGER:
          # TODO: save the integer somehow
          # TODO: check if more arguments are coming or a new instruction starts
          token = lex.next()
          echo "a ", token
          if token.kind == TokenType.WS:
            token = lex.peek()
            echo "b ", token

            if token.kind == TokenType.IDENTIFIER:
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              state = OPCODE
              # not advancing, letting them deal with saving the opcode themselves
            elif token.kind == TokenType.PERCENTAGE:
              state = IDENTIFIER
              discard lex.next() # only peeked, advancing now
            elif token.kind == TokenType.LPARAN:
              state = REGISTER
              discard lex.next() # only peeked, advancing now
            else: # can basically only be integer
              state = ARGUMENTS
              # not advancing

          else:
            # error
            echo "error, expected whitespace found something else"
            state = ERROR
          discard
        
        else:
          state = START # going back a bit and jumping to start
          discard lex.prev()

      of IDENTIFIER:
        if token.kind == TokenType.IDENTIFIER:
          # TODO: somehow save this identifier
          # TODO: check if more arguments are coming or a new instruction starts 
          token = lex.next()
          echo "a ", token
          if token.kind == TokenType.WS:
            token = lex.peek()
            echo "b ", token

            if token.kind == TokenType.IDENTIFIER:
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              state = OPCODE
              # not advancing, letting them deal with saving the opcode themselves
            elif token.kind == TokenType.PERCENTAGE:
              state = IDENTIFIER
              discard lex.next() # only peeked, advancing now
            elif token.kind == TokenType.LPARAN:
              state = REGISTER
              discard lex.next() # only peeked, advancing now
            else: # can basically only be integer
              state = ARGUMENTS
              # not advancing
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

      of RPARAN:
        if token.kind == TokenType.RPARAN:
          # TODO: check if more arguments are coming or a new instruction starts 
          token = lex.next()
          echo "a ", token
          if token.kind == TokenType.WS:
            token = lex.peek()
            echo "b ", token

            if token.kind == TokenType.IDENTIFIER:
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              state = OPCODE
              # not advancing, letting them deal with saving the opcode themselves
            elif token.kind == TokenType.PERCENTAGE:
              state = IDENTIFIER
              discard lex.next() # only peeked, advancing now
            elif token.kind == TokenType.LPARAN:
              state = REGISTER
              discard lex.next() # only peeked, advancing now
            else: # can basically only be integer
              state = ARGUMENTS
              # not advancing

        else:
          # error
          echo "error"
          state = ERROR
      
      of ERROR:
        echo "error in line ", lex.line, " at position ", lex.current

  return program;

#[
  TODO:
    - save values to some kind of "ast"
    - maybe allow opcode folled by argument without whitespace (the only way
      this could work is with non-integer arguments like "%label" or "(register)")
    - return the "ast"
]#