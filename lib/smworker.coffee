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
      new Promise(resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        accont = Config.get "sm.servers.#{ins}.account"
        incident = new IncidentMangement(server.trim(), port.trim(), account, Config.get "sm.servers.#{ins}.password")
        incident.incident_id = id
        incident.update(
          "Incident":
            "Solution": [msg],
            'Area':'hardware',
            "Subarea" :"missing or stolen",
            'AssignmentGroup':'Application',
            "Status":"Resolved",
            "JournalUpdates":['Ticket is resolved in ChatOps']
        )
        resolve()
  resolveTickert: (resp,robot) ->
    new Promise (resolve,reject)->
      incident_id = resp.match[1]
      solution = resp.match[2]?.substr(2).trimLeft() ||  "Resolved in ChatOps"
      channel = resp.message.rawMessage.channel
      robot.logger.debug "#{resp.match}"
      robot.logger.debug "incident id is #{incident_id}"
      robot.logger.debug "solution is #{solution}"
      robot.logger.debug "channel is #{channel}"
      resolveSMTicket= (body)->
        new Promise((resolve,reject)->
          reject() unless body.ok
          for item in body.items
            text = S(item.message.text).unescapeHTML().s
            match = /<.+>[\r\n]+ID=([\d\w]+)[\r\n]+SM=(.+)[\r\n]+DOCENGINE_URL=<(.+)>/mgi.exec text
            robot.logger.debug "Match result of #{text} is #{match}"
            if not match
              continue
            s = match[2]
            [server,port] = s.split(':')
            # docengine_url = match[3]

            robot.logger.debug "server:#{server}"
            robot.logger.debug "port:#{port}"
            robot.logger.debug "user:#{process.env.USER}"
#            robot.logger.debug "PASSWORD:#{process.env.PASSWORD}"
            incident = new IncidentMangement(server.trim(), port.trim(), process.env.USER, process.env.PASSWORD)
            incident.incident_id = incident_id.trim()
            incident.update(
              "Incident":
                "Solution": [solution],
                'Area':'hardware',
                "Subarea" :"missing or stolen",
                'AssignmentGroup':'Application',
                "Status":"Resolved",
                "JournalUpdates":['the ticket is resolved']
            )
            resolve()
        )
      api.pins.list({channel:channel}).then(resolveSMTicket)



module.exports = sm
