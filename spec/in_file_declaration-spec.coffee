temp = require('temp').track()
fs = require "fs"
path = require "path"

Plantuml = require '../lib/plantuml'

describe "Plantuml", ->
  [workspaceElement, activationPromise, directory, editor, buffer] = []

  beforeEach ->
    directory = temp.mkdirSync()

    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('plantuml')

  describe "when editor is open and plantuml:generate event is triggered", ->
    beforeEach ->
      directory = temp.mkdirSync()
      filePath = path.join(directory, 'tmpPlantuml.puml')
      fs.writeFileSync(filePath, '')

      waitsForPromise ->
        atom.workspace.open(filePath).then((e) ->
          editor = e
          buffer = editor.getBuffer()
          buffer.setText('@startuml{generated.png}\n(*) --> (*)\n@enduml')
        )

    it "generates an in-file declared png", ->
      done = false

      buffer.onDidSave((event)->
        console.log(event)
     )

      atom.workspace.onDidOpen((event)->
        console.log(event)
        if event.uri.indexOf("generated.png") > -1
          done = true
      )

      atom.commands.dispatch workspaceElement, 'plantuml:generate'

      waitsForPromise ->
        activationPromise

      runs ->
        waitsFor ->
          done is true
