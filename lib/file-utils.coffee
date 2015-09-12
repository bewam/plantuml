remote = require "remote"
path   = require "path"
dialog = remote.require "dialog"

module.exports =
class FileUtil
  constructor: () ->
  @prepareFile: (buffer) ->
    if buffer.file? && buffer.file.existsSync
      FileUtil.saveIfModified(buffer)
    else
      FileUtil.saveNewFile(buffer)

  @getPngFilePath:(file) ->
    pngFileName = FileUtil.getPngFilename(file)
    filePath = file.path.split(path.sep)
    filePath.pop()
    filePath.join(path.sep) + path.sep + pngFileName
  #
  # function getPngPathesFromBuffer: looks in the buffer of a plantuml
  # file if destinations are declared and output the in an array.
  # @param {object} buffer - atom.buffer
  # @return {array} pathes - each declaration path
  #
  @getPngPathesFromBuffer:(buffer) ->
    keyword = '@startuml'
    # FIXME: if you get better, then replace
    content = buffer.cachedText
    return if content.indexOf(keyword+'{') < 0
    pathes = [] # to be returned
    count = 0
    bufferFile = buffer.file
    for line in content.split("\n")
      do (line) ->
        # TODO: skip block comments /' ... '/
        i = line.indexOf(keyword)
        # if no a declaration or is a line comment.
        return if i < 0 or line.substr(0, i).indexOf("'") > -1
        # remove declaration
        exp = line.substr(i + 9)
        expPathIndex = exp.indexOf('{') + 1
        expPathLen = exp.indexOf('}') - 1
        # get the good
        expPath = exp.substr(expPathIndex, expPathLen).trim()
        isDir = FileUtil.pathIsDir(expPath)
        # remove file if one
        dir = if isDir then expPath else path.dirname(expPath)
        # let the current path if absolute else takes buffer one
        unless path.isAbsolute(dir)
          dir = path.join(path.dirname(bufferFile.path), dir)
        # fetch filename, if none, gives editor's one
        if isDir
          # if it's a generated name aka no name
          fileName = FileUtil.getGenName(path.basename(bufferFile.path), count)
          count++
        else
          fileName = path.basename(expPath)
        pathes.push(path.join(dir, fileName))
    return pathes

# private
  #
  # function getPngPathesFromBuffer: count >= 0, NAME.ext becomes NAME_001.png
  # @param {string} name - name of a file
  # @param {count} filename - position of filename in the plantuml source file
  # @return {string} filename
  #
  @getGenName : (name, count) ->
    c = ''
    pad = (n, width) ->
      n = String(n)
      if n.length < width
        new Array(width - n.length + 1).join(0) + n
    if count > 0
      c =  then "_" + pad(count, 3)
    # same as getPngFilename but add _XXX if needed
    fileName = path.basename(name, path.extname(name)) + c + '.png'

  # for plantuml, trailing slash means a dir
  @pathIsDir : (p) ->
    p.trim().charAt(p.length - 1) == path.sep

  @saveIfModified:(buffer) ->
    if buffer.isModified()
      buffer.save()
    !buffer.isModified() # no longer modified when successfully saved

  @saveNewFile:(buffer) ->
    path = dialog.showSaveDialog(
      {options:{title:'save plantuml file'}})
    if path?
      buffer.setPath(path)
      buffer.save()
    !buffer.isModified() # no longer modified when successfully saved

  @getPngFilename:(file) ->
    fileName = path.basename(file.path)
    if fileName.indexOf('.') > -1
      unsuffixedFileName = fileName.split('.')
      unsuffixedFileName.pop()
      fileName = unsuffixedFileName.join('.')
    fileName + '.png'
