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
    RPAREN
    ERROR

proc parse*(input: string): Prgm =
  lex.source = split_lines(input)

  var stack: seq[ParserState]
  var state: ParserState

  proc change_state(new_state: ParserState) =
    state = new_state
    # echo "new state: " & $new_state
    if new_state == ParserState.START:
      stack.set_len(0)
    stack.add(new_state)

  var lines: uint = 0
  change_state(START)

  var program = Prgm()
  var c_stmt: Stmt
  var c_instr: Instr

  while not is_at_end(lex):

    var token = lex.next()

    if token.kind == TokenType.WS: continue

    case state
      of START:
        c_stmt = Stmt()
        if token.kind == TokenType.IDENTIFIER:
          c_stmt.label = token.value
          change_state(COLON)
        elif token.kind == TokenType.OPCODE:
          # this does not work with the LDVR_* / STVR_* opcodes, therefore added LDVR/STVR as kind of intermediate
          c_instr = Instr(opcode: parse_enum[opcodes](token.value.toUpper))
          change_state(ARGUMENTS)
          c_stmt.label = ""
        else:
          echo "error, expected IDENTIFIER or OPCODE but got " & $token.kind
          change_state(ERROR)

      of COLON:
        if token.kind == TokenType.COLON:
          change_state(OPCODE)
        else:
          echo "error, expected COLON but got " & $token.kind
          change_state(ERROR)

      of OPCODE:
        if token.kind == TokenType.OPCODE:
          c_instr = Instr(opcode: parse_enum[opcodes](token.value.toUpper))
          change_state(ARGUMENTS)
        else:
          echo "error, expected OPCODE but got " & $token.kind
          change_state(ERROR)

      of ARGUMENTS:
        if token.kind == TokenType.PERCENTAGE: # label
          change_state(IDENTIFIER)
        elif token.kind == TokenType.LPAREN:
          change_state(REGISTER)
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
              change_state(START)
              # not advancing, letting them deal with saving the identifier themselves
            elif token.kind == TokenType.OPCODE:
              # save the current instruction and current statement
              c_stmt.instr = c_instr
              c_stmt.line = lines
              lines += 1
              program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
              change_state(OPCODE)
              # not advancing, letting them deal with saving the opcode themselves
            elif token.kind == TokenType.PERCENTAGE:
              change_state(IDENTIFIER)
              discard lex.next() # only peeked, advancing now
            elif token.kind == TokenType.LPAREN:
              change_state(REGISTER)
              discard lex.next() # only peeked, advancing now
            else: # can basically only be integer
              change_state(ARGUMENTS)
              # not advancing
          elif token.kind == TokenType.IDENTIFIER:
            discard lex.prev()
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            lines += 1
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            change_state(START)
          elif token.kind == TokenType.OPCODE:
            discard lex.prev()
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            lines += 1
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            change_state(OPCODE)
            # not advancing, letting them deal with saving the opcode themselves
          else:
            echo "error, expected whitespace or IDENTIFIER found something else: " & $token.kind & " (" & token.value & ")"
            change_state(ERROR)
          discard
        
        else:
          # save the current instruction and current statement
          c_stmt.instr = c_instr
          c_stmt.line = lines
          lines += 1
          program.lines.add(deep_copy(c_stmt))
          discard lex.prev()
          change_state(START) # going back a bit and jumping to start

      of IDENTIFIER:
        if token.kind == TokenType.IDENTIFIER: 
          c_instr.args.add(Arg(kind: ArgType.LABEL, value: token.value))
          # check if more arguments are coming or a new instruction starts
          token = lex.peek()
          if token.kind == TokenType.WS:
            token = lex.next()
          
          if token.kind == TokenType.IDENTIFIER:
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            lines += 1
            change_state(START)
            # not advancing, letting them deal with saving the identifier themselves
          elif token.kind == TokenType.OPCODE:
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            lines += 1
            change_state(OPCODE)
            # not advancing, letting them deal with saving the opcode themselves
          elif token.kind == TokenType.PERCENTAGE:
            change_state(IDENTIFIER)
            discard lex.next() # only peeked, advancing now
          elif token.kind == TokenType.LPAREN:
            change_state(REGISTER)
            discard lex.next() # only peeked, advancing now
          else: # can basically only be integer
            change_state(ARGUMENTS)
            # not advancing

      of REGISTER:
        if token.kind == TokenType.REGISTER:
          c_instr.args.add(Arg(kind: ArgType.REGISTER, value: token.value))
          change_state(RPAREN)
        else:
          echo "error, expected REGISTER but got " & $token.kind & " (" & token.value & ")"
          change_state(ERROR)

      of RPAREN:
        if token.kind == TokenType.RPAREN:
          # check if more arguments are coming or a new instruction starts 
          token = lex.next()
          var did_peek: bool
          if token.kind == TokenType.WS:
            did_peek = true
            token = lex.peek()

          if token.kind == TokenType.IDENTIFIER:
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            lines += 1
            if not did_peek:
              discard lex.prev()
            # not advancing, letting them deal with saving the identifier themselves
            change_state(START)
          elif token.kind == TokenType.OPCODE:
            # save the current instruction and current statement
            c_stmt.instr = c_instr
            c_stmt.line = lines
            program.lines.add(deep_copy(c_stmt)) # deep copying because c_stmt is reused
            lines += 1
            # need to reset statement here as it would otherwise not be overwritten correctly as the START
            # state is not used. This means that if no label is present the previous one might will be used.
            c_stmt = Stmt()
            if not did_peek:
              discard lex.prev()
            change_state(OPCODE)
            # not advancing, letting them deal with saving the opcode themselves
          elif token.kind == TokenType.PERCENTAGE:
            if did_peek:
              discard lex.next() # only peeked, advancing now
            change_state(IDENTIFIER)
          elif token.kind == TokenType.LPAREN:
            if did_peek:
              discard lex.next() # only peeked, advancing now
            change_state(REGISTER)
          else: # can basically only be integer
            if not did_peek:
              discard lex.prev()
            # not advancing
            change_state(ARGUMENTS)

        else:
          echo "error, expected PAREN but got " & $token.kind & " (" & token.value & ")"
          change_state(ERROR)
      
      of ERROR:
        # flushing current stmt and instr
        c_instr = nil;
        c_stmt = nil;
        echo "parser stack trace:"
        for s in stack:
          if s == ParserState.ERROR:
            continue
          echo "  " & $s
        echo "error in line ", lex.line, " at position ", lex.current,  "; current token: '" & token.value & "' (" & $token.kind & ")"

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