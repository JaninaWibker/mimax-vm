import tables
import noise
import strutils
import strformat
from instr import text_repr

import utils
import main
import vm
import instr
from cli import AnsiColor

proc one_step(vmstate: VMState, verbose: bool) =
    if verbose:
      let instr = text_repr(vmstate.buf[vmstate.iar])
      echo fmt"instr: {colorful(instr)}"
      
      let old_state = {
        "ra": vmstate.ra,
        "iar": vmstate.iar,
        "a": vmstate.a,
        "sp": vmstate.sp,
        "fp": vmstate.fp,
        "sar": vmstate.sar,
        "sdr": vmstate.sdr,
        "x": vmstate.x,
        "y": vmstate.y
      }.toOrderedTable
      discard vmstate.execute()
      let new_state = {
        "ra": vmstate.ra,
        "iar": vmstate.iar,
        "a": vmstate.a,
        "sp": vmstate.sp,
        "fp": vmstate.fp,
        "sar": vmstate.sar,
        "sdr": vmstate.sdr,
        "x": vmstate.x,
        "y": vmstate.y
      }.toOrderedTable

      var result = "state: "

      for key, old_value in old_state:
        let new_value = new_state[key]
        if new_value != oldvalue:
          result.add(fmt"{AnsiColor.f_white}{key.toUpper()}{AnsiColor.reset}: {AnsiColor.f_yellow}{old_value} -> {new_value}{AnsiColor.reset}, ")
        else:
          result.add(fmt"{AnsiColor.f_white}{key.toUpper()}{AnsiColor.reset}: {old_value}, ")
      echo result[0 .. result.len-3]
    else:
      discard vmstate.execute()

proc debug*(program: Prgm) =

  var vmstate = make_vm(program)

  var breakpoints: seq[uint]
  var verbose = false

  var noise = Noise.init()
  let prompt = Styler.init(fgBlue, "> ")

  const usage = fmt"""The following commands are available:
{AnsiColor.f_white}h{AnsiColor.reset},  {AnsiColor.f_white}help{AnsiColor.reset}                                   {AnsiColor.bold}|{AnsiColor.reset}  show this help menu
{AnsiColor.f_white}q{AnsiColor.reset},  {AnsiColor.f_white}quit{AnsiColor.reset}, {AnsiColor.f_white}exit{AnsiColor.reset}                             {AnsiColor.bold}|{AnsiColor.reset}  quit (^C also works)
{AnsiColor.f_white}i{AnsiColor.reset},  {AnsiColor.f_white}info{AnsiColor.reset}                                   {AnsiColor.bold}|{AnsiColor.reset}  show state of vm
{AnsiColor.f_white}it{AnsiColor.reset}, {AnsiColor.f_white}infotoggle{AnsiColor.reset}                             {AnsiColor.bold}|{AnsiColor.reset}  toggle details
{AnsiColor.f_white}d{AnsiColor.reset},  {AnsiColor.f_white}dis{AnsiColor.reset}                                    {AnsiColor.bold}|{AnsiColor.reset}  disassemble the program

{AnsiColor.f_white}s{AnsiColor.reset},  {AnsiColor.f_white}step{AnsiColor.reset}     {AnsiColor.f_yellow}<steps: uint>{AnsiColor.reset}                 {AnsiColor.bold}|{AnsiColor.reset}  step specified amount
{AnsiColor.f_white}s{AnsiColor.reset},  {AnsiColor.f_white}step{AnsiColor.reset}                                   {AnsiColor.bold}|{AnsiColor.reset}  alias of step 1
{AnsiColor.f_white}st{AnsiColor.reset}, {AnsiColor.f_white}stepto{AnsiColor.reset} {AnsiColor.f_yellow}<address: uint>{AnsiColor.reset}                 {AnsiColor.bold}|{AnsiColor.reset}  step to address
{AnsiColor.f_white}e{AnsiColor.reset},  {AnsiColor.f_white}exec{AnsiColor.reset}                                   {AnsiColor.bold}|{AnsiColor.reset}  execute until a breakpoint is hit or the vm halts

{AnsiColor.f_white}b{AnsiColor.reset},  {AnsiColor.f_white}break{AnsiColor.reset}    {AnsiColor.f_yellow}<address: uint>{AnsiColor.reset}               {AnsiColor.bold}|{AnsiColor.reset}  set breakpoint at address
{AnsiColor.f_white}br{AnsiColor.reset}, {AnsiColor.f_white}breakrel{AnsiColor.reset}   {AnsiColor.f_yellow}<offset: int>{AnsiColor.reset}               {AnsiColor.bold}|{AnsiColor.reset}  set breakpoint relative from current location
{AnsiColor.f_white}m{AnsiColor.reset},  {AnsiColor.f_white}mem{AnsiColor.reset} {AnsiColor.f_yellow}<address: uint>{AnsiColor.reset}                    {AnsiColor.bold}|{AnsiColor.reset}  inspect memory at address
{AnsiColor.f_white}m{AnsiColor.reset},  {AnsiColor.f_white}mem{AnsiColor.reset} {AnsiColor.f_yellow}<address: uint> = <value: int>{AnsiColor.reset}     {AnsiColor.bold}|{AnsiColor.reset}  update memory at address
{AnsiColor.f_white}r{AnsiColor.reset},  {AnsiColor.f_white}reg{AnsiColor.reset} {AnsiColor.f_yellow}<register: string>{AnsiColor.reset}                 {AnsiColor.bold}|{AnsiColor.reset}  inspect specified register
{AnsiColor.f_white}r{AnsiColor.reset},  {AnsiColor.f_white}reg{AnsiColor.reset} {AnsiColor.f_yellow}<register: string> = <value: int>{AnsiColor.reset}  {AnsiColor.bold}|{AnsiColor.reset}  update specified register
{AnsiColor.f_white}rs{AnsiColor.reset}, {AnsiColor.f_white}reset{AnsiColor.reset}                                  {AnsiColor.bold}|{AnsiColor.reset}  reset the state of the vm"""

  noise.setPrompt(prompt)

  echo "use \"$1h$2\" for help" % [$AnsiColor.f_white, $AnsiColor.reset]

  when prompt_preload_buffer:
    discard

  when prompt_history:
    var file = "history"
    discard noise.history_load(file)

  when prompt_completion:
    proc completion_hook(noise: var Noise, text: string): int =
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
        "r",  "reg",         "register",
        "rs", "res",         "reset"
      ]
      for w in words:
        if w.find(text) != -1:
          noise.add_completion(w)

    noise.set_completion_hook(completionHook)

  while true:
    let ok = noise.read_line()
    if not ok: break

    let line = noise.get_line().strip()

    var parts = line.split(" ")

    let command = parts[0]
    parts.delete(0)

    proc make_command(arg_count: int, usage: string, parts: seq[string], fn: proc(parts: seq[string]): void) =
      if parts.len < arg_count:
        echo fmt"{AnsiColor.bold}{AnsiColor.f_red}Error{AnsiColor.reset}: more arguments needed: {AnsiColor.f_white}{usage}{AnsiColor.reset}"
      elif parts.len > arg_count:
        echo fmt"{AnsiColor.bold}{AnsiColor.f_red}Error{AnsiColor.reset}: too little arguments: {AnsiColor.f_white}{usage}{AnsiColor.reset}"
      else:
        fn(parts)

    proc breakpoint(address: int): string =
      if address < 0:
        return fmt"{AnsiColor.bold}{AnsiColor.f_red}Error{AnsiColor.reset}: address below zero"
      else:
        let idx = breakpoints.find(cast[uint](address))
        if idx != -1:
          breakpoints.delete(idx)
          return fmt"{AnsiColor.bold}{AnsiColor.f_red}[-]{AnsiColor.reset} removed breakpoint at address {AnsiColor.f_blue}{address:#08X}{AnsiColor.reset}"
        else:
          breakpoints.add(cast[uint](address))
          return fmt"{AnsiColor.bold}{AnsiColor.f_green}[+]{AnsiColor.reset} added breakpoint at address {AnsiColor.f_blue}{address:#08X}{AnsiColor.reset}"

    
    case command:
      of "h", "help":
        echo usage
      of "q", "quit", "exit":
        break
      of "i", "info", "information":
        make_command(0, "i", parts, proc(args: seq[string]) =

          let instr = text_repr(vmstate.buf[vmstate.iar])

          let state = {
            "ra": vmstate.ra,
            "iar": vmstate.iar,
            "a": vmstate.a,
            "sp": vmstate.sp,
            "fp": vmstate.fp,
            "sar": vmstate.sar,
            "sdr": vmstate.sdr,
            "x": vmstate.x,
            "y": vmstate.y
          }.toOrderedTable

          var result = "state: "

          for key, value in state:
              result.add(fmt"{AnsiColor.f_white}{key.toUpper()}{AnsiColor.reset}: {AnsiColor.f_yellow}{value}{AnsiColor.reset}, ")

          echo fmt"instr: {colorful(instr)}"
          echo result[0 .. result.len-3]

        )
      of "it", "infotoggle", "informationtoggle":
        make_command(0, "it", parts, proc(args: seq[string]) =
        
          if verbose:
            verbose = false
            echo fmt"{AnsiColor.f_red}[-]{AnsiColor.reset} disabled verbose logging"
          else:
            verbose = true
            echo fmt"{AnsiColor.f_green}[+]{AnsiColor.reset} enabled verbose logging"

        )
      of "d", "dis", "disassemble":
        echo disassemble(program, true, true, cast[int](vmstate.iar))
      of "s", "step":

        proc step(args: seq[string]) =
          let n = string_to_uint(args[0])
          var i: uint = 0
          while i < n and vmstate.running:
            one_step(vmstate, verbose)
            i += 1
          
          if not vmstate.running:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset} (halted)"
          else:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset}"

        if parts.len == 0:
          step(@["1"])
        else:
          make_command(1, "s <steps: int>", parts, step)

      of "st", "stepto":
        make_command(1, "st <address: int>", parts, proc(args: seq[string]) =

          let address = string_to_uint(args[0])
          var i: uint = 0

          while vmstate.iar != address and vmstate.running:
            one_step(vmstate, verbose)
            i += 1

          if not vmstate.running:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset} (halted)"
          else:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset}"

        )
      of "e", "exec", "execute":
        make_command(0, "e", parts, proc(args: seq[string]) =

          var i = 0
          while vmstate.running and not breakpoints.contains(vmstate.iar):
            one_step(vmstate, verbose)
            i += 1

          if not vmstate.running:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset} (halted)"
          else:
            echo fmt"ran for {AnsiColor.f_blue}{i}{AnsiColor.reset} step(s); now at {AnsiColor.f_blue}{vmstate.iar:#08X}{AnsiColor.reset} (breakpoint hit)"

          )
        
      of "b", "break", "breakpoint":
        make_command(1, "b <address: int>", parts, proc(args: seq[string]) =

          echo breakpoint(string_to_int(args[0]))

        )
      of "br", "breakrel", "breakpointrelative":
        make_command(1, "br <offset: int>", parts, proc(args: seq[string]) =

          echo breakpoint(cast[int](vmstate.iar) + string_to_int(args[0]))
          
        )
      of "m", "mem", "memory":
        
        if parts.len == 1:
          make_command(1, "m <address: int>", parts, proc(args: seq[string]) =
            try:
              let address = string_to_uint(args[0])

              if address < cast[uint](vmstate.mem.len):
                let arr = vmstate.mem[address]
                let value = arr[0] * 65536 + arr[1] * 256 + arr[2] * 1
                let char_value = char(arr[0]) & char(arr[1]) & char(arr[2])
                echo fmt"value (decimal): {AnsiColor.f_blue}{value}{AnsiColor.reset}, value (hex): {AnsiColor.f_blue}{value:#08X}{AnsiColor.reset}, value (ascii): '{AnsiColor.f_blue}{char_value}{AnsiColor.reset}'"
              else:
                let limit = vmstate.mem.len - 1
                echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: invalid address (limit {limit})"

            except ValueError as e:
              echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: {AnsiColor.f_white}{e.msg}{AnsiColor.reset}"
              echo fmt"Usage: {AnsiColor.f_white}m <address: int>{AnsiColor.reset}"
          )
        elif parts.len == 3:
          make_command(3, "m <address: int> = <value: int>", parts, proc(args: seq[string]) =

            try:
              let address = string_to_uint(args[0])
              let equals = args[1]
              let value = string_to_uint(args[2]) # TODO: this could accept ints and then do the 2c conversion on it's own

              if equals != "=":
                raise new_exception(ValueError, "not an equal sign")

              if address >= cast[uint](vmstate.mem.len):
                let limit = vmstate.mem.len - 1
                echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: invalid address (limit {limit})"
              else:
                let arr = destruct(cast[uint](value))
                let value = arr[0] * 65536 + arr[1] * 256 + arr[2] * 1
                let char_value = char(arr[0]) & char(arr[1]) & char(arr[2])
                echo fmt"updated: value (decimal): {AnsiColor.f_blue}{value}{AnsiColor.reset}, value (hex): {AnsiColor.f_blue}{value:#08X}{AnsiColor.reset}, value (ascii): '{AnsiColor.f_blue}{char_value}{AnsiColor.reset}'"

            except ValueError as e:
              echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}:{AnsiColor.f_white}{e.msg}{AnsiColor.reset}"
              echo fmt"Usage: {AnsiColor.f_white}m <address: int> = <value: int>{AnsiColor.reset}"

          )
        else:
          echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: incorrect number of arguments: {AnsiColor.f_white}m <address: int>{AnsiColor.reset} or {AnsiColor.f_white}m <address: int> = <value: int>{AnsiColor.reset}"
        
      of "r", "reg", "register":
        
        if parts.len == 1:
          make_command(1, "r <address: int>", parts, proc(args: seq[string]) =

            try:
              let value = get_reg_by_string(vmstate, args[0])
              let arr = destruct(cast[uint](value))
              let char_value = char(arr[0]) & char(arr[1]) & char(arr[2])

              echo fmt"value (decimal): {AnsiColor.f_blue}{value}{AnsiColor.reset}, value (hex): {AnsiColor.f_blue}{value:#08X}{AnsiColor.reset}, value (ascii): {AnsiColor.f_blue}{char_value}{AnsiColor.reset}"

            except ValueError as e:
              echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: {AnsiColor.f_white}{e.msg}{AnsiColor.reset}"
              echo fmt"Usage: {AnsiColor.f_white}r <register: string>{AnsiColor.reset}"
          )
        elif parts.len == 3:
          make_command(3, "r <register: string> = <value: int>", parts, proc(args: seq[string]) =

            try:
              let register = args[0]
              let equals = args[1]

              if equals != "=":
                raise new_exception(ValueError, "not an equal sign")

              let value = string_to_uint(args[2]) # TODO: this could accept ints and then do the 2c conversion on it's own
              let arr = destruct(cast[uint](value))
              let char_value = char(arr[0]) & char(arr[1]) & char(arr[2])

              set_reg_by_string(vmstate, register, value)

              echo fmt"updated: value (decimal): {AnsiColor.f_blue}{value}{AnsiColor.reset}, value (hex): {AnsiColor.f_blue}{value:#08X}{AnsiColor.reset}, value (ascii): {AnsiColor.f_blue}{char_value}{AnsiColor.reset}"

            except ValueError as e:
              echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: {AnsiColor.f_white}{e.msg}{AnsiColor.reset}"
              echo fmt"Usage: {AnsiColor.f_white}r <register: string> = <value: int>{AnsiColor.reset}"

          )
        else:
          echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: incorrect number of arguments: {AnsiColor.f_white}r <register: string>{AnsiColor.reset} or {AnsiColor.f_white}r <register: string> = <value: int>{AnsiColor.reset}"

      of "rs", "res", "reset":
        make_command(0, "rs", parts, proc(args: seq[string]) =

          echo fmt"{AnsiColor.bold}{AnsiColor.f_red}VM reset{AnsiColor.reset}"
          vmstate = make_vm(program)

        )
      else:
        var rest = parts.join(" ")
        echo fmt"{AnsiColor.f_red}Error{AnsiColor.reset}: unknown command: {AnsiColor.f_blue}{command}{AnsiColor.reset} (arguments: {AnsiColor.f_blue}{rest}{AnsiColor.reset})"
        discard

    when prompt_history:
      if line.len > 0:
        noise.history_add(line)

    when prompt_history:
      discard noise.history_save(file)

  quit(0)