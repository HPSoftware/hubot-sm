###
Copyright 2016 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
Software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License. 
###


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
    get: (id, ins, account, password)->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        if account == null || account == undefined
          account  = Config.get "sm.servers.#{ins}.account"   
          password = Config.get "sm.servers.#{ins}.password"
        incident = new IncidentMangement(server.trim(), port.trim(), account, password)
        incident.get id, (e, body)->
          handleResponse _resolve, reject, e, body

    # update an incident
    update: (id, incident_data, ins, account, password) ->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        if account == null or account == undefined
          account  = Config.get "sm.servers.#{ins}.account"   
          password = Config.get "sm.servers.#{ins}.password"
        incident = new IncidentMangement(server.trim(), port.trim(), account, password)
        incident.incident_id = id
        incident.update("Incident": incident_data, (e, body)->
          handleResponse _resolve, reject, e, body
        )
    create: (incident_data, ins, account, password) ->
      new Promise (_resolve, reject) ->
        endpoint = Config.get "sm.servers.#{ins}.endpoint"
        [server, port] = endpoint.split(":")
        if account == null or account == undefined
          account  = Config.get "sm.servers.#{ins}.account"   
          password = Config.get "sm.servers.#{ins}.password"
        incident = new IncidentMangement(server.trim(), port.trim(), account, password )
        incident.create("Incident": incident_data, (e, body)->
          handleResponse _resolve, reject, e, body
        )
  change:
    update: (id, change_data, ins)->

#add shortcuts
sm.incident.resolve = (id, msg, ins, byUser, account, password)->
  data =
    Solution: msg
    Status: "Resolved"
    "UpdatedBy": byUser
    "JournalUpdates": ["Ticket resolved in ChatOps by #{byUser}"]
  sm.incident.update(id, data, ins, account, password)
  
sm.incident.assign = (id, people, ins, byUser, account, password)->
  data =
    Assignee: people
    "UpdatedBy": byUser
  sm.incident.update(id, data, ins, account, password)
  
sm.incident.addActivity = (id, msg, ins, byUser, account, password)->
  data =
    "UpdatedBy": byUser
    "JournalUpdates": [msg]
  sm.incident.update(id, data, ins, account, password)  
  
sm.incident.createIncident = (title, ins, createchannel, byUser, account, password)->
  data =
    "OpenedBy":byUser
    "Title":title
    "IncidentID":createchannel
    "Description":[title]
  sm.incident.create(data, ins, account, password) 

sm.change.approve = (id, msg, ins, byUser)->

module.exports = sm
