{CompositeDisposable} = require 'atom'

{prepareFile, getPngFilePath, getPngPathesFromBuffer} = require './file-utils'
{writeAndOpenPng} = require './plantuml-utils'

module.exports = Plantuml =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'plantuml:generate': => @generate()

  deactivate: ->
    @subscriptions.dispose()

  generate: ->
    if !atom.workspace.getActivePaneItem()?
      atom.notifications.addWarning('Could not read data.', {
        detail:'Please make sure to open the plantuml file first.'})
    else
      buffer = atom.workspace.getActivePaneItem().buffer
      prepared = prepareFile(buffer)
      if prepared
        pngPathes = getPngPathesFromBuffer(buffer)
        pngPathes = [ getPngFilePath(buffer.file) ] unless pngPathes
        umlFilePath = buffer.file.path

        for pngFilePath in pngPathes
          writeAndOpenPng(umlFilePath, pngFilePath)
      else
        atom.notifications.addWarning('Could not write file.', {
          detail:'Please make sure file can be written to disk.'})
