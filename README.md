#DSV Database

DSVDB is a simple CSV file or TSV file based database. Maintaining data
manually is as simple as working with a spreadsheet.

This database was designed for use as a append only database, with in-memory
caching.

##Installation

    npm install dsvdb

##Example

    dsvdb = require 'dsvdb'

Define a object model

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

An object of all object models

    models =
     Fruit: Fruit

Initialize database, where `testdata` is the path of the database.

    db = new dsvdb.Database 'testdata', models

Load all *Fruit* objects from files within directory `testdata/Fruit`.

    db.loadFiles 'Fruit', (err, model) ->
     console.log err, model

