import os
import strutils

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

const version = "0.0.1"
const usage = """
usage: mimax-vm <optional flags> <file>

flags:
  -b, --bin           Use binary representation as input
  -c, --compile       Compile to binary representation
  -v, --version       Print version
  -d, --debug         Enable debugging features (breakpoints, stepping through code, ...)
  -D, --disassemble   Disassemble binary representation
  -A, --alt-mima      Use slightly different mima instruction set
"""

proc parseOptions*(): Options =


  let count = paramCount()
  var options = Options(bin: false, compile: false, debug: false, disassemble: false, mima_version: mima_version.MIMAX)

  if count == 0:
    echo usage
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