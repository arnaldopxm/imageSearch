express = require 'express'
request = require 'request'
url = require 'url'
path = require 'path'
mongo = require('mongodb').MongoClient
app = express()
uri = process.env.URL
api = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=" + process.env.KEY + "&format=json&text="


app.set 'view engine', 'pug'
app.set 'views', path.join __dirname, 'views'

app.get '/', (req,res) ->
  res.render 'index'

returnjson = (obj) ->
  {url : "https://farm#{obj.farm}.staticflickr.com/#{obj.server}/#{obj.id}_#{obj.secret}.jpg",
  snippet : obj.title,
  thumbnail : "https://farm#{obj.farm}.staticflickr.com/#{obj.server}/#{obj.id}_#{obj.secret}_t.jpg"}

saveSearch = (query) ->
  mongo.connect uri, (err,db) ->
    throw err if err
    collection = db.collection 'searchs'

    doc =
      term : query
      when : new Date

    collection.insert doc, (err,data) ->
      throw err if err
      console.log "Search added #{query}"
      db.close()

app.get '/api/latest/imagesearch', (req,res) ->
  mongo.connect uri, (err,db) ->
    throw err if err
    collection = db.collection 'searchs'

    projection =
      _id : 0
      term : 1
      when : 1

    srt =
      when : -1

    collection.find({},projection).limit(10).sort(srt).toArray (err,data) ->
      throw err if err
      res.send data
      db.close()

app.get '/api/imagesearch/:search', (req,res) ->
  offset = url.parse(req.url,true).query.offset
  search = req.params.search

  saveSearch search

  pp = if offset? then offset else 10

  request api+search+"&per_page=#{pp}", (err,result,body) ->
    throw err if err
    body = JSON.parse body[14..-2]
    sol = body.photos.photo.filter (a) ->
      a.ispublic == 1
    sol = for id, val of sol
      returnjson val
    res.send sol

app.get '*', (req,res) ->
  res.redirect('/')

listener = app.listen process.env.PORT, ->
  console.log 'Your app is listening on port ' + listener.address().port
