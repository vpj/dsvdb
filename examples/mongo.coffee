mongo = require 'mongodb'

console.time 'init'
db = new mongo.Db 'cities',
 new mongo.Server 'localhost', 27017, {}
 safe: true
db.open ->
 db.collection 'cities', (e, collection) ->
  console.log e
  console.timeEnd 'init'
  console.time 'find'
  collection.find {}, (e2, cursor) ->
   console.log e2
   console.timeEnd 'find'
   console.time 'array'

   #cursor.count (e3, c) ->
   # console.log 'count', c

   n = 0
   next = ->
    cursor.nextObject (e3, obj) ->
     if e3?
      throw e3
      console.log e3
      console.log n
     if not obj?
      console.timeEnd 'array'
      console.log n
      return

     n++
     if n % 1000 is 0
      console.log n

     setImmediate next

   next()
   return

   #cursor.limit 10000, (e4, t) ->
   # console.log e4

   n = 0
   a = null
   each = ->
    cursor.each (e3, obj) ->
     if not obj?
      console.log n, a
      each()
      return

     n++
     a = obj

   each()


   return
   cursor.toArray (e3, objs) ->
    console.log e3
    console.timeEnd 'array'
    console.log objs.length

