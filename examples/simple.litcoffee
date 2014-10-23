    dsvdb = require '../index'

A basic database model

    class Fruit extends dsvdb.Collection
     model: 'Fruit'

     @defaults
      handle:
       type: 'string'
       default: ''
      name:
       type: 'string'
       default: ''
      price:
       type: 'decimal'
       default: 0

Load all objects of model *Fruit*

    dsvdb.loadFiles
     collection: Fruit
     separator: ','
     path: '../testdata/Fruit'
     (err, collection) ->
      console.log err
      console.log '--------------------'
      console.log collection

