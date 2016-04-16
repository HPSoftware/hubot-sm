_ = require('lodash')
IncidentMangement = require('./SMUtil')
S = require('string')
api = require './slack_web_api'
Promise = require 'bluebird'
co = require 'co'
Config = require './config'

sm =
  incident:
    resolve: (id, msg, ins) ->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        account = Config.get "sm.servers.#{ins}.account"
        incident = new IncidentMangement(server.trim(), port.trim(), account, Config.get "sm.servers.#{ins}.password")
        incident.incident_id = id
        incident.update(
          "Incident":
            "Solution": [msg],
            # 'Area':'hardware',
            # "Subarea" :"missing or stolen",
            # 'AssignmentGroup':'Application',
            "Status":"Resolved",
            "JournalUpdates":['Ticket is resolved in ChatOps']
        )

        _resolve()

module.exports = sm
