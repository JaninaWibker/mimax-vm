import tables
import streams
import noise
import strutils

import instr
import vm

proc execute_vm*(program: Prgm) =

  var labels = initTable[string, uint]()

  var buf: seq[array[3, uint8]]
  var mem: array[1024, array[3, uint8]]

  for stmt in program.lines:
    if stmt.label != "":
      labels[stmt.label] = stmt.line

  for stmt in program.lines:
    buf.add(bin_repr(stmt.instr, labels))

  var vmstate = makeVM(buf, mem)

  echo "initial: A:", vmstate.a, " SP: ", vmstate.sp, " IAR: ", vmstate.iar

  while vmstate.running:
    vmstate = vmstate.execute()
    echo "A:", vmstate.a, " SP: ", vmstate.sp, " IAR: ", vmstate.iar

  echo "halted"


proc compile*(program: Prgm): iterator(): uint8 =
  result = iterator(): uint8 =
    var labels = initTable[string, uint]()

    for stmt in program.lines:
      if stmt.label != "":
        labels[stmt.label] = stmt.line

    for stmt in program.lines:
      let bin = bin_repr(stmt.instr, labels)
      yield bin[0]
      yield bin[1]
      yield bin[2]


proc bin_to_program*(stream: FileStream): Prgm =

  var instr: array[3, uint8]
  var i = 0
  var line: uint = 0
  var program = Prgm()

  while not(stream.atEnd()):
    var curr: uint8
    discard stream.readData(curr.addr, 1)
    instr[i] = curr
    i = (i + 1) mod 3
    if i == 0:

      # construct statement and add to program
      var stmt = Stmt()
      var instr = text_repr(instr)
      stmt.line = line
      stmt.instr = instr
      # stmt.label would be good maybe, but don't know how this would be done tbh
      program.lines.add(stmt)
      line = line + 1

  return program

proc program_to_bin*(program: Prgm, stream: FileStream) =
  
  # write mima(x) header
  stream.write("mimax\0")

  let it = compile(program)

  for bit in it():
    stream.write(bit) 


proc disassemble*(program: Prgm): string =
  # TODO: can do a lot of improvements here like prettier output, generating labels based on what things are being CALL'ed, ...
  result = ""

  for stmt in program.lines:
    result.add($stmt & '\n')

proc debug*(program: Prgm) =

  var noise = Noise.init()
  let prompt = Styler.init(fgBlue, "> ") # TODO: maybe add some kind of indicator to this for the current state ([X] where X is some kind of state maybe)

  noise.setPrompt(prompt)

  when promptPreloadBuffer:
    discard

  when promptHistory:
    var file = "history"
    discard noise.historyLoad(file)

  when promptCompletion:
    proc completionHook(noise: var Noise, text: string): int =
      const words = [
        "h",  "help",
        "q",  "quit",        "exit",
        "i",  "info",        "information",
        "it", "infotoggle",  "informationtoggle",
        "d",  "dis",         "disassemble",
        "s",  "step",
        "st", "stepto",
        "e",  "exec",        "execute",
        "b",  "break",       "breakpoint",
        "br", "breakrel",    "breakpointrelative",
        "m",  "mem",         "memory",
        "r",  "reg",         "register"
      ]
      for w in words:
        if w.find(text) != -1:
          noise.addCompletion(w)

    noise.setCompletionHook(completionHook)

  while true:
    let ok = noise.readLine()
    if not ok: break

    let line = noise.getLine()

    var parts = line.split(" ")

    let command = parts[0]
    parts.delete(0)

    template make_command(arg_count: int, usage: string, parts: seq[string], fn: proc(parts: seq[string]): void) =
      if parts.len < arg_count:
        echo "more arguments needed: " & usage
      elif parts.len > arg_count:
        echo "too little arguments: " & usage
      else:
        fn(parts)
    
    case command:
      of "h", "help":
        echo "helppp" # TODO: come up with a good help text
      of "q", "quit", "exit":
        break
      of "i", "info", "information":
        echo "i: " & parts.join(" ")
      of "it", "infotoggle", "informationtoggle":
        echo "it"
      of "d", "dis", "disassemble":
        echo "d: " & parts.join(" ")
      of "s", "step":
        make_command(1, "s <steps: int>", parts, proc(args: seq[string]) =
          echo "TODO: stepping for ", parseInt(parts[0]), " steps"
        )
      of "st", "stepto":
        make_command(1, "st <address: int>", parts, proc(args: seq[string]) =
          echo "TODO: stepping to ", parseInt(parts[0])
        )
      of "e", "exec", "execute":
        echo "TODO: executing until next breakpoint or HALT"
      of "b", "break", "breakpoint":
        make_command(1, "b <address: int>", parts, proc(args: seq[string]) =
          echo "TODO: setting breakpoint at address ", parseInt(parts[0])
        )
      of "br", "breakrel", "breakpointrelative":
        make_command(1, "br <offset: int>", parts, proc(args: seq[string]) =
          echo "TODO: setting relative breakpoint at ", parseInt(parts[0])
        )
      of "m", "mem", "memory":
        echo "TODO: it's complicated m: " & parts.join(" ")
      of "r", "reg", "register":
        echo "TODO: it's complicated r: " & parts.join(" ")
      else:
        echo "unknown command: " & command
        echo "rest:            " & parts.join(" ")
        discard

    when promptHistory:
      if line.len > 0:
        noise.historyAdd(line)

    when promptHistory:
      discard noise.historySave(file)

  # TODO: this should be a debugger which allows inspecting values, setting breakpoints and stepping through code
  # * this is how it should work:
  # * command prompt where you can enter commands (shortened to single letters mostly; long version probably not even supported with arguments)
  # * displaying information & general things
  # * - h                     : print help menu (might also support "help")
  # * - q                     : quit (might also support "quit" and "exit")
  # * - i                     : print some information (this probably takes a lot of arguments)
  # * - it                    : toggle printing a lot of information on or off
  # * - d                     : disassemble (how much code is disassembled is still to be decided)
  # * stepping through code & breakpoints
  # * - s <n: int>            : step n steps forward (bypasses breakpoints)
  # * - s                     : alias of s 1
  # * - st <a: int>           : step to address a (bypasses breakpoints)
  # * - e                     : execute until a breakpoint is reached or the program HALTs
  # * - b <a: int>            : set a breakpoint at address a
  # * - br <n: int>           : set a breakpoint relative from the current location (+n)
  # * accessing values
  # * - m <a: int>            : read from memory at address a
  # * - r <r: reg>            : read from register r
  # * - m <a: int> = <v: int> : write v to memory at address a
  # * - r <r: reg> = <v: int> : write v to register r
  quit(0)