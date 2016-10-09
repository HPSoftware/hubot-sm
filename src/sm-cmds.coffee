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
moment = require 'moment'
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
          sendHelp room, ["Please use the correct syntax: 'sm get incident [ID]'.","To learn more about all supported commands, enter 'sm'."]
          return
        id = match[1]
        ins = match[2] or Config.get "sm.servers.default"

        SM.incident.get(id, ins)
          .then (r)->
            msg = robot.sm_ext.formatRecord r.body.Incident
            msg.channel = resp.message.rawMessage.channel
            #msg.text = "Incident `#{id}` - #{r.body.Incident.Title}"
            #msg.attachments[0].text = r.body.Incident.Description.join("\r")
            robot.emit 'slack.attachment', msg
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to retrieve incident #{id}", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg

        resp.reply "Retrieving Incident #{id}..."
      assign: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+assign\s+incident\s+([\w\d]+)\s+([\S]+)(?:\s+on\s+([\w\d]+))?/i.exec fullCmdLine
        if not match
          sendHelp room, ["Please use the correct syntax: 'sm assign incident [ID] [person]'.","To learn more about all supported commands, enter 'sm'."]
          return
        id = match[1]
        people = match[2]
        orginal_people = people
        ins = match[3] or Config.get "sm.servers.default"
        if people.indexOf("@") < 0
          email = robot.sm_ext.getEmailByName people
          if email != null
            people =email
        SM.incident.assign(id, people, ins, resp.message.user.email_address)
          .then (r)->
            resp.reply "Incident #{id} was assigned to #{orginal_people}."
          .catch (r) ->
            if r.body.Messages != null && r.body.Messages.length > 0
              msg = r.body.Messages[r.body.Messages.length-1]
              resp.reply "Failed to assign Incident #{id} to #{orginal_people}. \n*Reason*: #{msg}"
            else
              msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to assign Incident #{id} to #{orginal_people}", resp.message.rawMessage.channel, r
              robot.emit 'slack.attachment', msg
            
            
        resp.reply "Assigning Incident #{id} to #{orginal_people}..."
      resolve: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+resolve\s+incident\s+([\w\d]+)\s+\"([^\n]*)\"(?:\s+on\s+([\w\d]+))?/i.exec fullCmdLine
        if not match
          sendHelp room, ["Please use the correct syntax: `sm resolve incident [ID] \"[solution]\"'.","To learn more about all supported commands, enter 'sm'."]
          return
        id = match[1]
        solution = match[2]
        ins = match[3] or Config.get "sm.servers.default"
        
        SM.incident.resolve(id, solution, ins,resp.message.user.email_address)
          .then (r)->
             resp.reply "Incident #{id} was resolved."
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to resolve the incident #{id}", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg

        resp.reply "Resolving incident #{id}..."
      addactivity: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+addactivity\s+incident\s+([\w\d]+)\s+\"([^\n]*)\"(?:\s+on\s+([\w\d]+))?/i.exec fullCmdLine
        if not match
          sendHelp room, ["Please use the correct syntax: 'sm addactivity incident [ID] \"[activity]\"'.","To learn more about all supported commands, enter 'sm'."]
          return
        id = match[1]
        activity = match[2]
        ins = match[3] or Config.get "sm.servers.default"
        
        SM.incident.addActivity(id, activity, ins, resp.message.user.email_address)
          .then (r)->
            resp.reply "The activity was added to incident #{id}."
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to add the activity for incident #{id}", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg

        resp.reply "Adding the activity to incident #{id}..."
      create: (fullCmdLine, resp)->
        room = resp.message.room
        match = /sm\s+create\s+incident\s+\"([^\n]*)\"(?:\s+(-channel))?(?:\s+on\s+([\w\d]+))?/i.exec fullCmdLine
        if not match
          sendHelp room, ["Please use the correct syntax: 'sm create incident \"[description]\" -channel'. (\"-channel\" is optional.)","To learn more about all supported commands, enter 'sm'."]
          return
        title = match[1]
        createchannel=match[2] or false
        ins = match[3] or Config.get "sm.servers.default"
        if false!=createchannel
          createchannel=true
        SM.incident.createIncident(title, ins, createchannel, resp.message.user.email_address)
          .then (r)->
            robot.logger.debug r
            resp.reply "Incident #{r.body.Incident.IncidentID} was created!"
            msg = robot.sm_ext.formatRecord r.body.Incident
            msg.channel = resp.message.rawMessage.channel
            #msg.text = "Incident `#{r.body.Incident.IncidentID}` - #{r.body.Incident.Title}"
            #msg.attachments[0].text = r.body.Incident.Description.join("\r")
            robot.emit 'slack.attachment', msg
          .catch (r) ->
            robot.logger.debug r
            msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to create incident", resp.message.rawMessage.channel, r
            robot.emit 'slack.attachment', msg
        resp.reply "Creating new incident..."
        
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
          sendHelp room, ["Please specify an Incident `ID`", "To learn more about all supported commands, enter 'sm'."]
          return
        params = m[2].trim()
        if not params
          sendHelp room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats", "To learn more about all supported commands, enter 'sm'."]
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
          sendHelp room, ["Please specify a validate Service Manager Instance name", "To learn more about all supported commands, enter 'sm'."]
          return
        if not params
          sendHelp room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats", "To learn more about all supported commands, enter 'sm'."]
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
            wrongmsg = null;
            for msg in r.body.Messages
              if msg.indexOf(":{")!=-1 and msg.indexOf("}")!=-1
                nextpos=msg.indexOf(msg.indexOf(":{")+3,":")
                attrname=msg.substring(msg.indexOf(":{")+3,nextpos);
                robot.logger.info "find ignore field:"+attrname
                if keyValues[attrname] != null
                  wrongmsg=msg
            if wrongmsg == null
              resp.reply "Incident #{id} was updated"
            else
              resp.reply "Incident #{id} was updated, but some fields may be wrong."+wrongmsg
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
        robot.logger.info "start to attach"
        channel = resp.message.rawMessage.channel
        robot.logger.info "channel is "+resp
        robot.logger.info resp.message
        robot.logger.info resp.message.rawMessage
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
                  .catch (r) ->
                    robot.logger.info "gethistory error "+r
                    resp.reply "Fail to attaching converstaion to Service Manager Incident #{id}.\n*Reason*: #{r}"
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
                resp.reply "The conversation was attached to incident #{id}."
                cb(data)
              .catch (data) ->
                robot.logger.debug "Failed attaching conversation"
                robot.logger.debug data.body
                # res.reply "Failed to attach conversation: #{data}"
                slackMsg = robot.sm_ext.buildSlackMsgFromSmError "Failed to attach conversation to #{id}", channel, data
                robot.emit 'slack.attachment', slackMsg
                cb(data)
            resp.reply "Attaching the conversation to Incident #{id}..."
        ])

  # shortcuts

  # helpers
  # Method to resolve user name from
  reviseMessage = (message)->
    result = ""
    user_name = message.username
    if message.username == undefined
      user = robot.brain.userForId message.user
      user_name=user.name 
    text = message.text
    #m = /<@([\w\d]+)(\|([\w]+))?>/ig.exec text
    m = /<@([\w\d]+)(\|([\w]+))?>/ig.exec text
    # robot.logger.debug text
    if m
      if m[2]==undefined
        user = robot.brain.userForId m[1] 
        if user_name != user.name
          replaceText = '@'+user.name
        else
          replaceText =""        
      else if m[3] != undefined
        if user_name != m[3]
          replaceText = '@'+m[3]
        else
          replaceText =""   
      # robot.logger.debug user
      text = text.replace /<@([\w\d]+)(\|([\w]+))?>/ig, replaceText

    dateString = moment.unix(message.ts).format("MM/DD/YYYY HH:mm:SS")
    
    
    entity = "#{dateString} #{user_name} #{text}\r\n"
    result += entity
    if message.attachments
      _.each message.attachments ,(att)->
        if att.fields != null && att.fields != undefined
          k=1
          col=""
          for field in att.fields
            if k%2==1
              col += "\t * #{field.title}: #{field.value}\t\t"
            else
              col +="\t\t#{field.title}: #{field.value}\r\n"              
              result += col
              col="";
            k++
    result += "----------------------\r\n"
    return result
  helpAttach = [
    "Please use the correct syntax: 'sm attach-conversation incident [ID]' to attach channel converstaion to Service Manager Incident",
    "To learn more about all supported commands, enter 'sm'."
  ]
  helpSm = [
    "Use 'sm' to access Service Manager. Enter the following command for a list of available commands for the Service Manager Incident Management module:",
    "'sm incident'"
  ]

  helpIncident = [
    "Invalid command.",
    "Here are the all supported commands for Service Manager Incident Management module:",
    "* `sm get incident [ID] (on [sm instance])` - Retrieve the details of an incident by incident ID (e.g. IM10001)",
    "* `sm assign incident [ID] [person] (on [sm instance])` - Assign or reassign an incident to a person ([person] can be an email address, SM username, or Slack username)",
    "* `sm resolve incident [ID] \"[solution]\" (on [sm instance])` - Resolve an incident by providing a solution",
    "* `sm addactivity incident [ID] \"[activity]\" (on [sm instance])` - Add an activity to an incident",
    "* `sm create incident \"[description]\" -channel (on [sm instance])` - Create an incident as well as a Slack channel for the new incident (you can omit '-channel' to not create a Slack channel)",
    "* `sm update incident [ID] [field1=value2] [field2=value2] (on [sm instance])` - Update certain fields of an incident",
    "* `sm attach-conversation incident [ID] (on [sm instance])` - Attach the entire conversation history of the current channel to an incident"
  ]

  sendHelp = (channel, msg)->
    if robot.adapterName is 'slack'
      text = _.map(msg, (m)-> "_#{m}_").join("\r\n")
      robot.emit 'slack.attachment', {channel: channel, text: text, "response_type":"ephemeral"}
    else
      robot.send msg.join("\r\n")

  helpUnknown = (room, line)->
    sendHelp room, ["Invalid command.", "To learn more about all supported commands, enter 'sm'."]

  robot.respond /(.*)$/i, (resp)->
    room = resp.message.room
    fullLine = resp.match[1]
    match = /sm(.*)$/i.exec fullLine
    if not match
      helpUnknown room, fullLine
      return

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
