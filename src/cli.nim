import os
import strutils
import strformat

type
  mima_version* = enum
    MIMAX
    MIMA

type
  Options* = object
    bin*: bool
    compile*: bool
    debug*: bool
    disassemble*: bool
    mima_version*: mima_version
    filepath*: string

type
  AnsiColor* = enum
    bold      = "\e[1m",
    reset     = "\e[0m",
    f_black   = "\e[30m"
    f_red     = "\e[31m",
    f_green   = "\e[32m",
    f_yellow  = "\e[33m",
    f_blue    = "\e[34m",
    f_magenta = "\e[35m" ,
    f_cyan    = "\e[36m",
    f_white   = "\e[37m",

const version = "0.0.1"
const usage = fmt"""{bold}usage{reset}: {f_yellow}mimax-vm{reset} {f_white}<optional flags>{reset} {f_white}<file>{reset}

{bold}flags{reset}:
  {f_white}-b{reset}, {f_white}--bin{reset}           Use binary representation as input
  {f_white}-c{reset}, {f_white}--compile{reset}       Compile to binary representation (output: <file>.bin)
  {f_white}-v{reset}, {f_white}--version{reset}       Print version
  {f_white}-d{reset}, {f_white}--debug{reset}         Enable debugging features (breakpoints, stepping through code, ...)
  {f_white}-D{reset}, {f_white}--disassemble{reset}   Disassemble binary representation
  {f_white}-A{reset}, {f_white}--alt-mima{reset}      Use slightly different mima instruction set

{bold}examples{reset}:
  {f_yellow}mimax-vm{reset} {f_white}-b{reset} {f_white}-d{reset} {f_white}test.bin.mimax{reset}
  {f_yellow}mimax-vm{reset} {f_white}-D{reset}    {f_white}test.bin.mimax{reset}"""

proc parseOptions*(): Options =


  let count = paramCount()
  var options = Options(bin: false, compile: false, debug: false, disassemble: false, mima_version: mima_version.MIMAX)

  if count == 0:
    echo usage
    quit(0)
  elif count >= 1:
    for key in countup(1, count):
      let value = param_str(key)

      if starts_with(value, "--"):

        if value == "--version":
          echo "version: ", version
          quit(0)
        elif value == "--bin":
          options.bin = true;
        elif value == "--compile":
          options.compile = true;
        elif value == "--debug":
          options.debug = true
        elif value == "--disassemble":
          options.disassemble = true
        elif value == "--alternative":
          options.mima_version = mima_version.MIMA

      elif starts_with(value, "-"):

        for flag in value:
          if flag == '-':
            continue
          elif flag == 'v':
            echo "version: ", version
            quit(0)
          elif flag == 'b':
            options.bin = true;
          elif flag == 'c':
            options.compile = true;
          elif flag == 'd':
            options.debug = true
          elif flag == 'D':
            options.disassemble = true
          elif flag == 'A':
            options.mima_version = mima_version.MIMA
      
      elif key == count:
        options.filepath = value
      else:
        continue

  return options