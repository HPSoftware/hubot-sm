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
      if e
        callback e if callback?
      else
        r =
          code: res.statusCode
          body: JSON.parse body
        callback null, r if callback?
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

    request options, (e, res, body) ->
      if e
        callback(e) if callback?
      else
        r =
          code: res.statusCode
          body: JSON.parse body
        callback null, r if callback?

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
