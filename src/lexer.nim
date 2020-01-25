import re

import token

type
  Rule* = object
    regex*: Regex
    kind*: TokenType
    max_length: int
    # multi_line: bool # this would be false for everything except maybe WS, don't know if I should add/keep it

type
  Lexer* = ref object
    source*: seq[string]
    tokens*: seq[Token]
    rules*: seq[Rule]
    current*: int
    line*: int

proc isAtEnd*(lex: Lexer): bool =
  if lex.source.len == 0: return true
  if lex.tokens.len == 0: return false
  if lex.tokens[lex.tokens.len-1].kind == TokenType.EOF: return true

proc next*(lex: Lexer): Token =
  # for debugging:
  #   echo lex.current, " ", lex.source[lex.line].len
  #   echo lex.line, " ", lex.source.len

  # at end of line
  if lex.current == lex.source[lex.line].len:
    if lex.line == lex.source.len - 1:
      let token = Token(kind: TokenType.EOF)
      if not isAtEnd(lex):
        lex.tokens.add(token)
      return token
    else:
      lex.current = 0
      lex.line = lex.line + 1

  # main code
  for rule in lex.rules:
    let match = matchLen(lex.source[lex.line], rule.regex, lex.current)#, lex.current + rule.max_length)
    if match != -1:
      # saving to value because lex.current is modified before the return
      let value = lex.source[lex.line][lex.current .. lex.current + match - 1]
      # for debugging
      #   echo "rule: ", rule.kind
      #   echo "match: \"", value, "\""
      lex.current = lex.current + match
      let token = Token(kind: rule.kind, line: lex.line, value: value)
      lex.tokens.add(token)
      return token
  
  if lex.source[lex.line] == "":
    let token = Token(kind: TokenType.WS, line: lex.line, value: "\n")
    if lex.line != lex.source.len - 1: # if last line don't do anything, if not then go to next line
      lex.line = lex.line + 1
      lex.current = 0
    return token
  # found something completely unknown, skipping to end of line and continuing
  # (not going to next line directly as this better going to be handled by the EOF/line logic)
  let value = lex.source[lex.line][lex.current .. lex.source[lex.line].len - 1]
  lex.current = lex.source[lex.line].len
  return Token(kind: TokenType.Unknown, line: lex.line, value: value)

var rules = newSeq[Rule]()

# mneomonics are ordered by length, this circumvents the issue that STV and STVR, ... start the same which causes everything to match STV instead of STVR
rules.add(Rule(kind: TokenType.OPCODE,      max_length: 4, regex: re("LDIV|STIV|HALT|CALL|LDVR|STVR|LDSP|STSP|LDFP|STFP|LDRA|STRA|LDC|LDV|STV|ADD|AND|XOR|NOT|RAR|EQL|JMP|JMN|RET|ADC|OR", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.REGISTER,    max_length: 3, regex: re("IR|RA|IAR|A|ONE|SP|FP|SAR|SDR|X|Y", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.INTEGER,     max_length: 0, regex: re("[+-]?(0x[0-9a-fA-F]+|0b[01]+|[0-9]+)", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.IDENTIFIER,  max_length: 0, regex: re("[a-zA-Z_][a-zA-Z_0-9]+", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.WS,          max_length: 0, regex: re("(?:\t|\n|\r| |;.*|#.|--.*)+", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.COLON,       max_length: 1, regex: re(":", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.LPARAN,      max_length: 1, regex: re("\\(", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.RPARAN,      max_length: 1, regex: re("\\)", {reIgnoreCase})))
rules.add(Rule(kind: TokenType.PERCENTAGE,  max_length: 1, regex: re("%", {reIgnoreCase})))

# just some testing
var lex*: Lexer

lex = Lexer(rules: rules)
