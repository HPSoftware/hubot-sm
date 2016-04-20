_ = require('lodash')
IncidentMangement = require('./SMUtil')
S = require('string')
# api = require './slack_web_api'
Promise = require 'bluebird'
# co = require 'co'
Config = require './config'

sm =
  incident:
    # update an incident
    update: (id, incident_data, ins) ->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        account = Config.get "sm.servers.#{ins}.account"
        incident = new IncidentMangement(server.trim(), port.trim(), account, Config.get "sm.servers.#{ins}.password")
        incident.incident_id = id
        incident.update("Incident": incident_data, (e, body)->
          if e
            reject e
          else if body.code isnt 200
            reject body
          else
            _resolve body
        )

#add shortcuts
sm.incident.resolve = (id, msg, ins, byUser)->
  data =
    Solution: [msg]
    Status: "Resolved"
    "JournalUpdates": ["Ticket resolved in ChatOps by #{byUser}"]
  sm.incident.update(id, data, ins)

module.exports = sm
