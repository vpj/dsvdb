    dsvdb = require '../index'

A basic database model

    class City extends dsvdb.Collection
     model: 'City'

     @defaults
      Country:
       type: 'string'
       default: ''
      City:
       type: 'string'
       default: ''
      Region:
       type: 'number'
       default: 0
      Population:
       type: 'number'
       default: 0
      Latitude:
       type: 'decimal'
       default: 0
      Longitude:
       type: 'decimal'
       default: 0

Load all objects of model *City*

    console.log 'starting'
    console.time 'load'
    file = new dsvdb.File
     collection: City
     separator: ','
     file: '../testdata/small.csv'
    file.read (err, collection) ->
     console.timeEnd 'load'
     console.log err
     console.log '--------------------'
     console.log collection.length
     save collection

    save = (collection) ->
     console.log 'saving'
     file = new dsvdb.File
      separator: ','
      collection: City
      file: '../testdata/save.csv'
     for f in collection.files
      f.file = file
     file.write collection, ->
      console.log 'done'


