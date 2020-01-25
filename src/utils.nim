import streams
import os

proc read_binary_file*(filepath: string): FileStream = 
  if unlikely(not existsFile(filepath)):
    raise newException(IOError, "file \"{filepath}\" does not exist")
  
  let stream = newFileStream(filepath, mode = fmRead)
  defer: stream.close()

  # check if mima file 
  var mima_header: array[4, char]
  discard stream.readData(mima_header.addr, 4)

  doAssert mima_header == ['m', 'i', 'm', 'a'], "This is not a mima binary file"

  # check if mima-x file
  var mima_version_header: array[1, char]
  discard stream.readData(mima_version_header.addr, 1)

  doAssert mima_version_header == ['x'], "This is not a mima x binary file (but a mima binary file)"

  return stream


proc read_text_file*(filepath: string): string =
  if unlikely(not existsFile(filepath)):
    raise newException(IOError, "file \"{filepath}\" does not exist")

  return readFile(filepath)