import streams
import os
import strutils
import parseutils
import strformat
from cli import mimaversion

proc read_binary_file*(filepath: string, version: mima_version): FileStream = 
  if unlikely(not file_exists(filepath)):
    raise new_exception(IOError, fmt"file '{filepath}' does not exist")
  
  let stream = new_file_stream(filepath, mode = fmRead)

  # check if mima file 
  var mima_header_start: array[4, char]
  var mima_header_end:   array[2, char]

  discard stream.read_data(mima_header_start.addr, 4)
  discard stream.read_data(mima_header_end.addr, 2)

  if mima_header_start == ['m', 'i', 'm', 'a']:
    # little endian system
    if version == mima_version.MIMAX and mima_header_end == ['x', '\0']:
      # echo "little endian system"
      discard
    elif version == mima_version.MIMA:
      discard # TODO: what to do here?
    else:
      raise new_exception(IOError, "This is not a mimax binary file")
    discard
  elif mima_header_start == ['i', 'm', 'a', 'm']:
    # big endian system
    if mima_header_end == ['\0', 'x']:
      echo "big endian system"
    else:
      raise new_exception(IOError, "This is not a mimax binary file")
  else:
    raise new_exception(IOError, "This is not a mima binary file")

  return stream


proc read_text_file*(filepath: string): string =
  if unlikely(not file_exists(filepath)):
    raise new_exception(IOError, fmt"file '{filepath}' does not exist")

  return readFile(filepath)

proc string_to_int*(input: string): int =
  if input == "": return 0

  var local_input = input
  var is_negative = input.starts_with("-")

  if is_negative:
    local_input = input[1 .. input.len-1]

  var rtn: int
  
  if local_input.starts_with("0x"):
    if parse_hex(local_input[2..local_input.len-1], rtn) == 0:
      raise new_exception(ValueError, "Parsed (hex) integer is not valid")
  elif local_input.starts_with("0b"):
    if parse_bin(local_input[2..local_input.len-1], rtn) == 0:
      raise new_exception(ValueError, "Parsed (bin) integer is not valid")
  elif local_input.starts_with("0"):
    if local_input == "0":
      result = 0
    elif parse_oct(local_input[1..local_input.len-1], rtn) == 0:
      raise new_exception(ValueError, "Parsed (oct) integer is not valid")
  else:
    rtn = parse_int(local_input)

  if is_negative:
    return -rtn
  else:
    return rtn

proc string_to_uint*(input: string): uint =
  var rtn = string_to_int(input)
  if rtn < 0:
    raise new_exception(ValueError, "Parsed integer is negative")
  else:
    return cast[uint](rtn)
