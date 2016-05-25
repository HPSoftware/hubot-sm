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


_ = require 'lodash'
Config = require '../lib/config'
SM = require '../lib/smworker'
async = require 'async'
S = require('string')
module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)
  # mapping
  sm =
    incident:
      get: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+get\s+incident\s+([\w\d]+)(?:\s+on\s+([\w\d]+))?/i.exec fullCmdLine
        if not match
          sendHelp room, ["Please use `sm get incident [ID]` to get an instance of Service Manager Incident", "For other commands, please check `sm`"]
          return
        id = match[1]
        ins = match[2] or Config.get "sm.servers.default"

        SM.incident.get(id, ins)
          .then (r)->
            robot.logger.debug "Success #{r}"
            msg = robot.sm_ext.formatRecord r.body.Incident
            msg.channel = resp.message.rawMessage.channel
            msg.text = "Incident `#{id}` - #{r.body.Incident.Title}"
            msg.attachments[0].text = r.body.Incident.Description.join("\r")
            robot.emit 'slack.attachment', msg
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to retrieve incident #{id}", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg

        resp.reply "Retrieving Incident #{id}..."
      update: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+update\s+incident(.*)/i.exec fullCmdLine
        if not match
          sendHelp room, helpIncident
          return
        params = match[1]
        #check id
        m = /([\d\w]+)(.*)/i.exec params
        id = m[1] if m?
        if not id
          sendHelp room, ["Please specify an Incident `ID`", "For other commands, please check `sm`"]
          return
        params = m[2].trim()
        if not params
          sendHelp room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats", "For other commands, please check `sm`"]
          return

        m = /(.*)?on\s+([\w\d]+)$/i.exec params
        ins = if m
                params = m[1]
                m[2]
              else
                Config.get "sm.servers.default"

        # check instance
        data = Config.get "sm.servers.#{ins}"
        if not data
          sendHelp room, ["Please specify a validate Service Manager Instance name", "For other commands, please check `sm`"]
          return
        if not params
          sendHelp room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats", "For other commands, please check `sm`"]
          return


        # Clean up utf8 quotations
        params = params.replace  /[\u201C|\u201D]/g, '"'
        params = params.replace /[\u2019|\u2018]/g, "'"
        reg = /([\w\d\.]+)=(?:(?:'([^']+)')|(?:"([^"]+)")|(\S+))/gi
        m = reg.exec params
        keyValues = {}
        while(m)
          # console.log m
          value = m[2] or m[3] or m[4]
          keyValues[m[1]] = value
          m = reg.exec params
        robot.logger.debug "Update Incident data"
        robot.logger.debug keyValues

        SM.incident.update(id, keyValues, ins)
          .then (r)->
            robot.logger.debug r
            resp.reply "Incident #{id} updated"
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to update incident #{id}", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg

        resp.reply "Updating Incident #{id} on #{ins}<#{Config.get "sm.servers."+ins+".endpoint"}>....."
      attach: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+attach-conversation\s+incident\s*([\w\d]+)\s*(?:on (.+))?/i.exec fullCmdLine
        if not match
          sendHelp room, helpAttach
          return
        id = match[1]
        # robot.logger.debug res.match
        ins = match[2] or Config.get "sm.servers.default"

        # robot.logger.debug "SM instance is #{ins}"
        serverEndpoint = Config.get("sm.servers.#{ins}.endpoint")
        [server, port] = serverEndpoint.split ":"
        account = Config.get("sm.servers.#{ins}.account")
        robot.logger.debug "To attach conversation to #{id} on #{serverEndpoint}"
        latest_ts = 0
        result = []
        has_more = true
        # TODO: this is Slack specific
        channel = resp.message.rawMessage.channel
        async.waterfall([
          (cb)->
            async.whilst(
              ()->  has_more
              (cb1)->
                robot.sm_ext.getHistory(channel, latest_ts)
                  .then (data)->
                    has_more = data.has_more
                    result = _.concat(result, data.messages)
                    latest_ts = _.last(data.messages).ts if data.messages and data.messages.length > 1
                    cb1(null)
              (err)->
                cb(null, result)
            )

          (messages,cb)->
            robot.logger.debug "server:#{server}"
            robot.logger.debug "port:#{port}"
            robot.logger.debug "user:#{account}"
            # robot.logger.debug "PASSWORD:#{Config.get("sm.servers.#{ins}.password")}"
            # robot.logger.debug "Doc Engine URL : #{docengine_url}"
            robot.logger.debug "incident id is #{id}"
            robot.logger.debug "message count is #{messages.length}"
            texts = []
            texts.push(reviseMessage(m)) for m in messages
            texts = texts.reverse()
            incident_data =
              "review.detail": ["attach conversation"],
              "JournalUpdates": texts
            SM.incident.update(id, incident_data, ins)
              .then (data)->
                resp.reply "Conversation has been attached to Incident #{id} as Journal update"
                cb(data)
              .catch (data) ->
                robot.logger.debug "Failed attaching conversation"
                robot.logger.debug data.body
                # res.reply "Failed to attach conversation: #{data}"
                slackMsg = robot.sm_ext.buildSlackMsgFromSmError "Failed to attach conversation to #{id}", channel, data
                robot.emit 'slack.attachment', slackMsg
                cb(data)
            resp.reply "Attaching converstaion to Service Manager Incident #{id}..."
        ])

  # shortcuts

  # helpers
  # Method to resolve user name from
  reviseMessage = (message)->
    result = {}
    text = message.text
    m = /<@([\w\d]+)(\|([\w]+))?>/ig.exec text
    # robot.logger.debug text
    if m
      user = robot.brain.userForId m[1]
      replaceText = if user.email_address
                      "[#{user.name}:#{user.email_address}]"
                    else
                      "[#{user.name}]"
      # robot.logger.debug user
      text = text.replace /<@([\w\d]+)(\|([\w]+))?>/ig, replaceText
    result ={
      text: text
      attachments: message.attachments
    }
    return JSON.stringify(result)
  helpAttach = [
    "Please use `sm attach-conversation incident [ID]` to attach channel converstaion to Service Manager Incident"
  ]
  helpSm = [
    "Hi, use `sm` to access Service Manager. Try following command to continue...",
    "* `sm incident` - to access Service Manager Incident Management module"
  ]

  helpIncident = [
    "Hi, you can do a lots on Service Manager Incident Management module",
    "* `sm get incident [ID] (on [sm instance])` - Get a Service Manager incident by ID",    
    "* `sm update incident [ID] [field1=value2] [field2=value2] (on [sm instance])` - Update a Service Manager incident",
    "* `sm attach-conversation incident [ID] (on [sm instance])` - Attach conversation in this channel to Service Manager incident"
  ]

  sendHelp = (channel, msg)->
    if robot.adapterName is 'slack'
      text = _.map(msg, (m)-> "_#{m}_").join("\r\n")
      robot.emit 'slack.attachment', {channel: channel, text: text, "response_type":"ephemeral"}
    else
      robot.send msg.join("\r\n")

  helpUnknown = (room, line)->
    sendHelp room, ["Hi, I don't get that `#{line}`. Try using `sm` to see what you can do with Service Manager"]

  robot.respond /(.*)$/i, (resp)->
    room = resp.message.room
    fullLine = resp.match[1]
    match = /sm(.*)$/i.exec fullLine
    # if not match
    #   helpUnknown room, fullLine
    #   return

    # we support following command so for
    # Syntax sm <verb> <entity> (params)
    # sm get incident
    # sm update incident
    # sm attach incident
    cmdline = match[1].trim()
    robot.logger.debug "To respond #{cmdline} in room #{room}"
    [verb, entity] = cmdline.split(/\s+/)
    # in case sm incident
    entity = entity or verb
    verb = 'attach' if verb == 'attach-conversation'

    if not entity
      # print sm help
      sendHelp room, helpSm
      return

    entityFx = sm[entity.trim()]
    robot.logger.debug "To check #{entity} with #{entityFx}"
    if not entityFx
      helpUnknown room, fullLine
      return

    if not verb or not entityFx[verb]
      sendHelp room, helpIncident
      return

    entityFx[verb](fullLine, resp)
