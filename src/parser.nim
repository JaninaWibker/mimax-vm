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
  var c_stmt: Stmt
  var c_instr: Instr

  while not isAtEnd(lex):

    var token = lex.next()

    if token.kind == TokenType.WS: continue

    case state
      of START:
        c_stmt = Stmt()
        if token.kind == TokenType.IDENTIFIER:
          c_stmt.label = token.value
          state = COLON
        elif token.kind == TokenType.OPCODE:
          c_instr = Instr(opcode: parseEnum[opcodes](token.value))
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
          c_instr = Instr(opcode: parseEnum[opcodes](token.value))
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
          c_instr.args.add(Arg(kind: ArgType.INTEGER, value: token.value))
          # check if more arguments are coming or a new instruction starts
          token = lex.next()
          if token.kind == TokenType.WS:
            token = lex.peek()

            if token.kind == TokenType.IDENTIFIER:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
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
          # save the current instruction and current statement
          c_stmt.instr = c_instr
          program.lines.add(deep_copy(c_stmt))
          state = START # going back a bit and jumping to start
          discard lex.prev()

      of IDENTIFIER:
        if token.kind == TokenType.IDENTIFIER: 
          c_instr.args.add(Arg(kind: ArgType.LABEL, value: token.value))
          # check if more arguments are coming or a new instruction starts
          token = lex.next()
          if token.kind == TokenType.WS:
            token = lex.peek()

            if token.kind == TokenType.IDENTIFIER:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
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
          c_instr.args.add(Arg(kind: ArgType.REGISTER, value: token.value))
          state = RPARAN
        else:
          # error
          echo "error"
          state = ERROR

      of RPARAN:
        if token.kind == TokenType.RPARAN:
          # check if more arguments are coming or a new instruction starts 
          token = lex.next()
          if token.kind == TokenType.WS:
            token = lex.peek()

            if token.kind == TokenType.IDENTIFIER:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
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
        # flushing current stmt and instr
        c_instr = nil;
        c_stmt = nil;
        echo "error in line ", lex.line, " at position ", lex.current

  return program;

#[
  TODO:
    - save values to some kind of "ast"
    - maybe allow opcode folled by argument without whitespace (the only way
      this could work is with non-integer arguments like "%label" or "(register)")
    - return the "ast"
]#