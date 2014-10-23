#DSV Database

DSVDB is a simple CSV file or TSV file based database. Maintaining data
manually is as simple as working with a spreadsheet.

This database was designed for use as a append only database, with in-memory
caching.

*[Github - https://github.com/vpj/dsvdb](https://github.com/vpj/dsvdb)*

    fs = require 'fs'
    d3 = require 'd3'

Find files in a directory

    findFiles = (dir, callback) ->
     fileList = []
     err = []

     callbackCount = 0

     done = ->
      callbackCount--
      if callbackCount is 0
       err = null if err.length is 0
       callback err, fileList

     recurse = (path) ->
      callbackCount++
      fs.readdir path, (e1, files) ->
       if e1?
        err.push e1
        done()
        return

       for file in files
        continue if file[0] is '.'
        do (file) ->
         f = "#{path}/#{file}"
         callbackCount++
         fs.stat f, (e2, stats) ->
          if e2?
           err.push e2
           done()
           return

          if stats.isDirectory()
           recurse f
          else if stats.isFile()
           fileList.push f
          done()

       done()

     recurse dir

## Database
Setup the database with a set of models and a directory. The models will reside
in subdirectories with the same name.

Each model should be a subclass of `Model` class.

    class Database
     constructor: (path, models, options = {}) ->
      @models = models
      @path = path
      @collections = []
      @separator = options.separator
      @separator ?= ','

####Save a set of models

     save: (model, file, callback) ->
      #TODO

####Load files
This will load all the files of type `model` recursing over the subdirectories.

     getPath: (model) -> "#{@path}/#{model}"

     loadFiles: (model, callback) ->
      path = "#{@path}/#{model}"
      objs = null
      files = []
      err = []
      n = 0

      loadFile = =>
       if n >= files.length
        err = null if err.length is 0
        callback err, objs
        return

       @loadFile model, files[n], (e, obj) ->
        if e?
         err.push e
        else
         if not objs?
          objs = obj
         else
          objs.merge obj
        n++
        loadFile()

      findFiles path, (e, f) ->
       err = e
       err ?= []
       files = f
       loadFile()

####Load file
Loads a single file of type model

     loadFile: (model, file, callback) ->
      collection = new Collection
       id: @collections.length
       model: @models[model]
       file: file
       db: this
      @collections.push collection
      collection.read callback


## Collection class

    class Collection
     constructor: (options) ->
      @db = options.db
      @id = options.id
      @model = new options.model db: @db
      @file = options.file
      @parser = @_getParser @db.separator

     _getParser: (separator) ->
      if separator is ","
       d3.csv.parseRows
      else if separator is "\t"
       d3.tsv.parseRows
      else
       d3.dsv(separator, "text/plain").parseRows

     read: (callback) ->
      #TODO Streaming
      fs.readFile @file, encoding: 'utf8', (e1, data) =>
       console.log 'file read'
       data = "#{data}"
       console.log "in string"
       #data = data.split '\n'
       #console.log "split"
       if e1?
        callback msg: "Error reading file: #{@file}", err: e1, null
        return

       try
        data = @parser "#{data}"
       catch e2
        callback msg: "Error parsing file: #{@file}", err: e2, null
        return

       console.log "parsing"
       try
        @model.load @id, data
       catch e3
        throw e3
        callback msg: "Error loading file: #{@file}", err: e3, null
        return

       callback null, @model



## Model class
Introduces class level function initialize and include. This class is the base
class of all other data models. It has `appendt` method to add data.
The structure of the object is defined by `defaults`.

    class Model
     constructor: ->
      @_init.apply @, arguments

     _initialize: []

####Register initialize functions.
All initializer funcitons in subclasses will be called with the constructor arguments.

     @initialize: (func) ->
      @::_initialize = @::_initialize.slice()
      @::_initialize.push func

     _init: ->
      for init in @_initialize
       init.apply @, arguments

####Include objects.
You can include objects by registering them with @include. This solves the problem of single inheritence.

     @include: (obj) ->
      for k, v of obj when not @::[k]?
       @::[k] = v


     model: 'Model'

     _defaults: {}

####Register default key value set.
Subclasses can add to default key-values of parent classes

     @defaults: (defaults) ->
      @::_defaults = JSON.parse JSON.stringify @::_defaults
      for k, v of defaults
       @::_defaults[k] = v

Build a model with the structure of defaults. `options.db` is a reference to the `Database` object, which will be used when updating the object. `options.file` is the path of the file, which will be null if this is a new object.

     @initialize  (options) ->
      @db = options.db
      @collections = []
      @values = {}
      @length = 0
      for k of @_defaults
       @values[k] = []

###Save the object

     save: (callback) ->
      #TODO

     _getParser: (key) ->
      switch @_defaults[key].type
       when 'string' then (x) -> x
       when 'number' then parseInt
       when 'decimal' then parseFloat

###Load data

     load: (collectionId, data) ->
      return unless data.length > 1

      columns = {}
      header = data[0]
      for k, c in header
       if @_defaults[k]?
        columns[k] = c

      for k, c of columns
       i = 1
       values = @values[k]
       parser = @_getParser k
       while i < data.length
        try
         values.push parser data[i][c]
        catch e
         throw e
        ++i

      for k, v of @_defaults when not columns[k]?
       i = 1
       values = @values[k]
       v = @_defaults[k].default
       while i < data.length
        values.push v
        ++i

      @collections.push
       collection: collectionId
       from: @length
       to: @length + data.length - 1
      @length += data.length - 1

     merge: (model) ->
      if model.model isnt @model
       throw new Error 'Incompatible merge'

      for c in model.collections
       @collections.push
        collection: c.collection
        from: c.from + @length
        to: c.to + @length

      @length += model.length

      for k of @_defaults
       @values[k] = @values[k].concat model.values[k]


#Exports

    exports.Database = Database
    exports.Model = Model
