request = require 'request'
async = require('async')
{ok, equal, fail} = require('assert')
_ = require('lodash')


DEFAULT_SM_SERVER = "16.187.186.51"
#DEFAULT_SM_SERVER = "localhost"
DEFAULT_SM_SERVER_PORT = "13080"

#BASE_URL = "http://#{DEFAULT_SM_SERVER}:#{DEFAULT_SM_SERVER_PORT}/SM/9/rest"
class RestMethod
  constructor: (@smserver = DEFAULT_SM_SERVER, @port = DEFAULT_SM_SERVER_PORT, @user = "System.Admin", @password = "") ->
    @baseurl = "http://#{@smserver}:#{@port}/SM/9/rest"

  getResp: (url, callback = null) ->
    options =
      url: url
      method: 'GET'
      headers:
        'Content-Type': 'application/json'
        "User-Agent": 'NodeJS'
        "accept-encoding": "gzip, deflate"
      auth:
        user: @user
        pass: @password

    request(options, (e, res, body) ->
      if(err? )
        console.log err

      equal res.statusCode, 200
      callback(JSON.parse(body) ) if callback?
    )

  postResp: (url, opts, callback = null) ->
    options =
      url: url
      method: 'POST'
      headers:
        'Content-Type': 'application/json'
        "User-Agent": 'NodeJS'
        "accept-encoding": "gzip, deflate"
        'accept-language': 'en-US,en;q=0.9'
        'accept': '*/*'
      auth:
        user: @user
        pass: @password
      body: JSON.stringify(opts)

    request(options, (e, res, body) ->
      if(err? )
        console.log err

      equal res.statusCode, 200
      callback(JSON.parse(body) ) if callback?
    )

# Business Data Model for SM Incident Record
class IncidentMangement extends RestMethod
  constructor: (smserver, port, user, ps) ->
    super(smserver, port, user, ps)
    @incident_id = null

  get: (id, callback) ->
    url = "#{@baseurl}/incidents/#{id}"
    @.getResp(url, callback)
    @incident_id = id

  getlist: (callback) ->
    url = "#{@baseurl}/incidents"
    @.getResp(url, callback)

  create: (opts, callback = null) ->
    url = "#{@baseurl}/incidents"
    @.postResp(url, opts, callback)

  update: (opts, callback = null) ->
    url = "#{@baseurl}/incidents/#{@incident_id}/action/update"
    @.postResp(url, opts, callback)

  close: (opts,callback=null)->
    url = "#{@baseurl}/incidents/#{@incident_id}/action/close"
    @.postResp(url,opts,callback)


module.exports = IncidentMangement

#=========== sample test code =============
# incident = new IncidentMangement()
# incident.getlist()
# incident_id = null
# async.waterfall([
#   (cb)->
#     incident.create(
#       "Incident":
#         "action": ["Rest API description"]
#         "brief.description": "major incident created from nodejs app"
#         "category": "incident"
#         "initial.impact": "2"
#         "assignment": "Application"
#         "affected.item": "Applications"
#         "major.incident": true
#         "owner": "Adrian.Baxt",
#       (jobj)->
#         incident_id = jobj['Incident']['IncidentID']
#         console.log "a major incident #{incident_id} is created"
#         cb(null, incident_id)
#     )
# , (id, cb)->
#     console.log "incident id ", id
#     incident.incident_id = id
#     incident.update(
#       "Incident":
#         "JournalUpdates": [ "test11"]
#       #      "JournalUpdates": ["08/04/08 12:54:14 US/Mountain (falcon):", "test11"]
#     )
#     incident.get(incident.incident_id, (o)->console.log(o))
#     cb()
# ]
# )
