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

  var lines: uint = 0

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
          echo "error"
          state = ERROR

      of COLON:
        if token.kind == TokenType.COLON:
          state = OPCODE
        else:
          echo "error"
          state = ERROR

      of OPCODE:
        if token.kind == TokenType.OPCODE:
          c_instr = Instr(opcode: parseEnum[opcodes](token.value))
          state = ARGUMENTS
        else:
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
              c_stmt.line = lines
              lines += 1
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              c_stmt.line = lines
              lines += 1
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
            echo "error, expected whitespace found something else"
            state = ERROR
          discard
        
        else:
          # save the current instruction and current statement
          c_stmt.instr = c_instr
          c_stmt.line = lines
          lines += 1
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
              c_stmt.line = lines
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              lines += 1
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              c_stmt.line = lines
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              lines += 1
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
          echo "error"
          state = ERROR

      of REGISTER:
        if token.kind == TokenType.REGISTER:
          c_instr.args.add(Arg(kind: ArgType.REGISTER, value: token.value))
          state = RPARAN
        else:
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
              c_stmt.line = lines
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              lines += 1
              state = START
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              c_stmt.line = lines
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              lines += 1
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
          echo "error"
          state = ERROR
      
      of ERROR:
        # flushing current stmt and instr
        c_instr = nil;
        c_stmt = nil;
        echo "error in line ", lex.line, " at position ", lex.current

  return program;


# TODO: maybe allow opcode followed by argument without whitespace (the only way
# TODO: this could work is with non-integer arguments like "%label" or "(register)") 


#[
  The idea behind this giant procedure is to be sort of like a recursive descent parser,
  but since the grammar is so easy just do everything in place in one giant switch
  (or rather case because that's the name in nim) statement which switches over different
  states, each state corresponding to what should be parsed next or how it is conventionally
  done another procedure which tries to parse the expected into an AST of it's own to be later
  combined with other parts into another AST, ... till a whole AST of the whole program exists.
  
  The grammar that this giant case statement is parsing is the following:
  
    start       -> ((label:)? instruction)*
    instruction -> opcode arg*
    opcode      -> OPCODE_KEYWORD
    arg         -> (label|INTEGER|\(REGISTER\)|<fehlt hier noch etwas?>)
    label       -> IDENTIFIER
  
]#