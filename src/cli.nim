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

const bold   = "\e[1m"
const reset  = "\e[0m"
const white  = "\e[37m"
const yellow = "\e[33m"

const version = "0.0.1"
const usage = fmt"""{bold}usage{reset}: {yellow}mimax-vm{reset} {white}<optional flags>{reset} {white}<file>{reset}

{bold}flags{reset}:
  {white}-b{reset}, {white}--bin{reset}           Use binary representation as input
  {white}-c{reset}, {white}--compile{reset}       Compile to binary representation (output: <file>.bin)
  {white}-v{reset}, {white}--version{reset}       Print version
  {white}-d{reset}, {white}--debug{reset}         Enable debugging features (breakpoints, stepping through code, ...)
  {white}-D{reset}, {white}--disassemble{reset}   Disassemble binary representation
  {white}-A{reset}, {white}--alt-mima{reset}      Use slightly different mima instruction set

{bold}examples{reset}:
  {yellow}mimax-vm{reset} {white}-b{reset} {white}-d{reset} {white}test.bin.mimax{reset}
  {yellow}mimax-vm{reset} {white}-D{reset}    {white}test.bin.mimax{reset}"""

proc parseOptions*(): Options =


  let count = paramCount()
  var options = Options(bin: false, compile: false, debug: false, disassemble: false, mima_version: mima_version.MIMAX)

  if count == 0:
    echo usage
    quit(0)
  elif count >= 1:
    for key in countup(1, count):
      let value = paramStr(key)

      if startsWith(value, "--"):

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

      elif startsWith(value, "-"):

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