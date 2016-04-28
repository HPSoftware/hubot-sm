_ = require('lodash')
IncidentMangement = require('./SMUtil')
S = require('string')
# api = require './slack_web_api'
Promise = require 'bluebird'
# co = require 'co'
Config = require './config'
Log            = require 'log'
logger     = new Log process.env.HUBOT_LOG_LEVEL or 'info'

handleResponse = (resolve, reject, e, body)->
  console.log "Handle response #{body}"
  if e
    reject e
    return
  if body.code is 200
    resolve body
    return
      
  reject body

sm =
  incident:
    get: (id, ins)->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        account = Config.get "sm.servers.#{ins}.account"
        incident = new IncidentMangement(server.trim(), port.trim(), account, Config.get "sm.servers.#{ins}.password")
        incident.get id, (e, body)->
          handleResponse _resolve, reject, e, body

    # update an incident
    update: (id, incident_data, ins) ->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        account = Config.get "sm.servers.#{ins}.account"
        incident = new IncidentMangement(server.trim(), port.trim(), account, Config.get "sm.servers.#{ins}.password")
        incident.incident_id = id
        incident.update("Incident": incident_data, (e, body)->
          handleResponse _resolve, reject, e, body
        )
  change:
    update: (id, change_data, ins)->

#add shortcuts
sm.incident.resolve = (id, msg, ins, byUser)->
  data =
    Solution: [msg]
    Status: "Resolved"
    "JournalUpdates": ["Ticket resolved in ChatOps by #{byUser}"]
  sm.incident.update(id, data, ins)

sm.change.approve = (id, msg, ins, byUser)->

module.exports = sm
