import streams
import os
import cli # TODO: create some kind of better system than just including everything everwhere; similar to header files?

proc read_binary_file*(filepath: string, version: mima_version): FileStream = 
  if unlikely(not existsFile(filepath)):
    raise newException(IOError, "file \"{filepath}\" does not exist")
  
  let stream = newFileStream(filepath, mode = fmRead)
  defer: stream.close()

  # check if mima file 
  var mima_header_start: array[4, char]
  var mima_header_end:   array[2, char]

  discard stream.readData(mima_header_start.addr, 4)
  discard stream.readData(mima_header_end.addr, 2)

  if mima_header_start == ['m', 'i', 'm', 'a']:
    # little endian system
    if version == mima_version.MIMAX and mima_header_end == ['x', '\0']:
      echo "little endian system"
    elif version == mima_version.MIMA:
      discard # TODO: what to do here?
    else:
      raise newException(IOError, "This is not a mimax binary file")
    discard
  elif mima_header_start == ['i', 'm', 'a', 'm']:
    # big endian system
    if mima_header_end == ['\0', 'x']:
      echo "big endian system"
    else:
      raise newException(IOError, "This is not a mimax binary file")
  else:
    raise newException(IOError, "This is not a mima binary file")

  return stream


proc read_text_file*(filepath: string): string =
  if unlikely(not existsFile(filepath)):
    raise newException(IOError, "file \"{filepath}\" does not exist")

  return readFile(filepath)