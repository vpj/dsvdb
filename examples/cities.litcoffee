    dsvdb = require '../index'

A basic database model

    class City extends dsvdb.Model
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

An object of all object models

    models =
     City: City

Initialize database

    db = new dsvdb.Database '../testdata', models

Load all objects of model *City*


    console.log 'starting'
    console.time 'load'
    db.loadFiles 'City', (err, model) ->
     console.timeEnd 'load'
     console.log err, model.length

