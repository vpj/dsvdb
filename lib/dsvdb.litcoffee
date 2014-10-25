#DSV Database

DSVDB is a simple CSV file or TSV file based database. Maintaining data
manually is as simple as working with a spreadsheet.

This database was designed for use as a append only database, with in-memory
caching.

*[Github - https://github.com/vpj/dsvdb](https://github.com/vpj/dsvdb)*

    fs = require 'fs'
    dsv = require '../dsv/'

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

## Save and load methods

###Load files
This will load all the files of type `collection` recursing over the subdirectories.

    loadFiles = (options, callback) ->

####Options
`collection` - reference to collection class
`path` - path in filesystem
`separator` - separator; `,` for CSV files and `\t` for TSV files

     objs = null
     files = []
     err = []
     n = 0

     next = =>
      if n >= files.length
       err = null if err.length is 0
       callback err, objs
       return

      file = new File
       collection: options.collection
       file: files[n]
       separator: options.separator

      file.read (e, obj) ->
       if e?
        err.push e
       else
        if not objs?
         objs = obj
        else
         objs.merge obj
       n++
       next()

     findFiles options.path, (e, f) ->
      err = e
      err ?= []
      files = f
      next()


## File class

    class File
     constructor: (options) ->
      @separator = options.separator
      @collection = options.collection
      @file = options.file

     write: (collection, callback) ->
      encoding = 'utf8'
      console.time 'write'
      values = collection.values
      files = collection.files
      rows = []
      for f in files
       if f.file.file is @file
        rows = rows.concat [f.from...f.to]

      header = collection.header
      writer = fs.createWriteStream @file, encoding: encoding
      N = rows.length
      console.log header

      getLine = (n) ->
       s = ""
       if n is -1
        for h, i in header
         s += @separator if i isnt 0
         s += "\"#{h}\""
       else
        r = rows[n]
        for h, i in header
         s += @separator if i isnt 0
         s += "\"#{values[h][n]}\""

       s += "\n"

       return s

      finish = ->
       console.log 'finished'
       console.timeEnd 'write'
       callback()

      write = ->
       console.log 'writing', line
       ok = true
       while line < N and ok
        s = getLine line
        ++line

        if line is N
         writer.write s, encoding, finish
        else
         ok = writer.write s, encoding

       if line < N
        writer.once 'drain', write

      line = -1
      write()



     read: (callback) ->
      #TODO Streaming
      console.time 'read'
      fs.readFile @file, encoding: 'utf8', (e1, data) =>
       console.timeEnd 'read'
       data = "#{data}"
       console.log "in string"
       #data = data.split '\n'
       #console.log "split"
       if e1?
        callback msg: "Error reading file: #{@file}", err: e1, null
        return

       console.time 'parse'
       try
        data = dsv text: "#{data}", separator: @separator
       catch e2
        callback msg: "Error parsing file: #{@file}", err: e2, null
        return

       console.timeEnd 'parse'
       console.time 'collect'
       collection = new @collection
       if data.length <= 0
        callback null, collection
        return

       header = collection.header
       console.log header
       columns = {}
       for col, c in data
        for h in header
         if col[0] is h
          columns[h] = col
          break
        data[c] = []

       try
        collection.load file: this, data: columns
       catch e3
        throw e3
        callback msg: "Error loading file: #{@file}", err: e3, null
        return

       console.timeEnd 'collect'
       callback null, collection



## Collection class
Introduces class level function initialize and include. This class is the base
class of all other data collections. It has `append` method to add data.
The structure of the object is defined by `defaults`.

    class Collection
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
      @files = []
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

     @::__defineGetter__ 'header', ->
      (k for k of @_defaults)

###Load data

     load: (options) ->
      file = options.file
      data = options.data
      N = 0
      for k, col of data
       N = col.length
      return unless N > 0

      for k, col of data
       values = @values[k]
       parser = @_getParser k
       #console.time k
       for d in col
        try
         d = parser d
        catch e
         #values.push @_defaults[k].default
         throw e
        values.push d
       #console.timeEnd k
       data[k] = null

      for k, v of @_defaults when not data[k]?
       i = 0
       values = @values[k]
       v = @_defaults[k].default
       while i < N
        values.push v
        ++i

      @files.push
       file: file
       from: @length
       to: @length + N
      @length += N

     merge: (collection) ->
      if collection.model isnt @model
       throw new Error 'Incompatible merge'

      for f in collection.files
       @files.push
        file: f.file
        from: f.from + @length
        to: f.to + @length

      @length += collection.length

      for k of @_defaults
       @values[k] = @values[k].concat collection.values[k]


#Exports

    exports.File = File
    exports.Collection = Collection
    exports.loadFiles = loadFiles
