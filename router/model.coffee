express = require 'express'
mysql = require 'mysql2'
Q = require 'q'
moment = require 'moment'

config = require 'config'
connection = null

handleDisconnect = () ->
  connection = mysql.createConnection(config.mysql)
  connection.connect()
  connection.on 'error', (err) ->
    console.log 'err', err
    if !err.fatal
      throw err
    if err.code == 'ECONNREFUSED'
      console.log 'Re-connecting lost connection: ' + err.stack
      setTimeout ()->
        handleDisconnect connection
      , 10000
    else
      console.log 'Re-connecting lost connection: ' + err.stack
      setTimeout ()->
        handleDisconnect connection
      , 1000

handleDisconnect()


router = express.Router()

router.get '/models', (req, res)->
  connection.query "SHOW TABLES", (err, rows, fields)->
    if err
      res.send 500
    else
      console.log 'rows', rows
      res.json rows.map (row)->
        row["Tables_in_#{config.mysql.database}"]

router.route '/:key'
.get (req, res) ->
  key = req.params.key
  select = '*'
  if req.query.$select
    fields = req.query.$select
    select = fields.join ','
  limit = 10
  offset = 0
  if req.query.$limit
    limit = req.query.$limit
  if req.query.$offset
    offset = req.query.$offset


  connection.query "SELECT #{select} FROM #{key} ORDER BY timestamp desc LIMIT #{offset}, #{limit}", (err, rows, fields)->
    if err
      console.log err
      res.sendStatus 500
    else
      res.json rows.map (row)->
        row.timestamp = moment(row.timestamp).format('YYYY-MM-DD HH:mm:ss')
        row

router.get '/:key/count', (req, res)->
  key = req.params.key
  connection.query "SELECT count(id) FROM #{key}", (err, rows, fields)->
    if err
      console.log err
      res.sendStatus 500
    else
      totalItemCount = rows[0]['count(id)']
      res.json
        totalItemCount: totalItemCount

router.get '/:key/chart/:date', (req, res)->
  date = moment().format('YYYY-MM-DD')
  console.log('req.params.date', req.params.date);
  if req.params.date
    date = req.params.date
  key = req.params.key
  hours = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
  promises = hours.map (hour)->
    deferred = Q.defer()
    beginTime = moment(date + ' 00:00:00').add(hour, 'hours').format('YYYY-MM-DD HH:mm:ss')
    endTime = moment(date + ' 00:00:00').add(hour + 1, 'hours').format('YYYY-MM-DD HH:mm:ss')
    connection.query "SELECT count(id) FROM #{key} WHERE timestamp BETWEEN '#{beginTime}' AND '#{endTime}'", (err, rows, fields)->
      if err
        console.log err
        deferred.reject()
      else
        deferred.resolve
          hour: hour
          count: rows[0]['count(id)']
    deferred.promise
  Q.all promises
  .then (counts)->
    result =
      columns: [
        ['Количество']
      ]
    counts.forEach (count)->
      result.columns[0].push count.count

    res.json result
  .fail ()->
    res.sendStatus 500
router.get '/:key/create', (req, res)->
  key = req.params.key
  connection.query ("CREATE TABLE `#{key}` (" +
    "`id` int(10) NOT NULL AUTO_INCREMENT," +
    " `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
    " `tag` varchar(32) NOT NULL DEFAULT ''," +
    " `payload` json DEFAULT NULL, PRIMARY KEY (`id`)" +
    " `ip` VARCHAR(32) DEFAULT NULL," +
    " `status` VARCHAR(32) DEFAULT NULL," +
    " `payload` json DEFAULT NULL, PRIMARY KEY (`id`)" +
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8 "), (err, row, fields)->
    res.json status: "ok"

router.route '/:key/:id'
.get (req, res, next) ->
  key = req.params.key
  id = req.params.id
  connection.query "SELECT * FROM #{key} where id=#{id}", (err, rows, fields)->
    if err
      console.log err
      res.sendStatus 500
    else
      res.json rows[0]

module.exports = router