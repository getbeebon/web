express = require 'express'
session = require 'express-session'
bodyParser = require 'body-parser'

server = (config)->

  app = express()
  init = ()->
    app.set 'views', "#{__dirname}/views"
    app.set 'view engine', 'pug'

    app.use '/bower_components', express.static "#{__dirname}/bower_components"
    app.use '/public', express.static "#{__dirname}/public"
    app.use bodyParser.json()
    app.use '/keys', require './router/model'

    app.get '/partials/:view', (req, res)->
      res.render 'partials/' + req.params.view

    app.get '/', (req, res)->
      res.render 'index'

  run = ()->
    init()
    app.listen(config.web.port)

  run: run

module.exports = server