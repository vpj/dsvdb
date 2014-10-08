    dsvdb = require './lib/dsvdb'

A basic database model

    class Fruit extends dsvdb.Model
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
       default: ''

    models =
     Fruit: Fruit

Initialize database

    db = new dsvdb.Database 'testdata', models

Load all objects of model *Fruit*

    db.loadFiles 'Fruit', (err, model) ->
     console.log err, model

