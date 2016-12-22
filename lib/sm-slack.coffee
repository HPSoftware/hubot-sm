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

#"Title", "Description",, "JournalUpdates", "UpdatedTime", "UpdatedBy" 
# SM actions for Slack

Querystring = require 'querystring'
SlackApi = require './slack_web_api'
Promise = require 'bluebird'
_ = require 'lodash'
class SmExt
  constructor: (robot, apiToken = process.env.SLACK_APP_TOKEN, botToken=process.env.HUBOT_SLACK_TOKEN)->
    @robot = robot
    @apiToken = apiToken
    @botToken = botToken
       
       
  formatRecord: (record)->
    slackform =["IncidentID", "RequestedBy","Status", "ContactPerson","Phase", "Company", "Location","PrimaryAffectedService","PrimaryAffectedServiceUCMDBID","MajorIncident",  "AffectedCI","AffectedCIGlobalID","Escalated", "IncidentManager", "Category","Impact","SubCategory","Urgency","Area","Priority","AssignmentGroup","Source", "Assignee","CompletionCode", "Solution", "OpenTime", "ClosedTime", "ClosedBy" ]
    fields = []
    if record["Title"] != undefined && record["Description"]!=undefined
      r =
        title: record["IncidentID"].toString()+"- "+record["Title"].toString()
        value: record["Description"].toString()
        short: false
      fields.push(r)
    for field in slackform
      if record[field] != null && undefined != record[field]
        r =
          title: field
          value: record[field].toString()
          short: true
        fields.push(r)
    att =
      fields: fields
      #mrkdwn_in: ["text", "pretext"]
      color: 'warning'
    slackMessage =
      mrkdwn: true
      attachments:[att]

  buildSlackMsgFromSmError: (msg, channel, data)->
    #if data.body.Incident
    #  slackMessage = this.formatRecord data.body.Incident
    #  slackMessage.text = msg
    #  slackMessage.channel = channel
    #  slackMessage.attachments[0].text = "*Reason*: _#{data.body.Messages.join('\r')}_"
    #  return slackMessage
    #else
    err ="Unrecoverable error in application "
    if data.body.Messages.length > 0
      for num in [(data.body.Messages.length-1)..0]
        err = data.body.Messages[num]
        if err.indexOf("(")==-1 and err.indexOf(")")==-1
          break
    text = """
      #{msg}
      "*Reason*: _#{err}_"
      """
    slackMessage =
      text: text
      channel: channel
      mkdown: true

  formatChannelName: (prefix, roomName)->
    # length of slack channel name must be 21 or less
    if roomName.length >=21
      roomName
    else
      "#{prefix.substring(0, 20-roomName.length)}-#{roomName}"

  getHistory: (channel, latest_ts=0, count=1000)->
    opts =
      token: @apiToken
      channel: channel
      count: count
      latest: latest_ts

    SlackApi.channels.history opts

  createRoom: (name)->
    opts =
      token: @apiToken
      name: name
    SlackApi.channels.create opts

  setTopic: (channelId, topic)->
    opts =
      token: @apiToken
      channel: channelId
      topic: topic
    SlackApi.channels.setTopic opts

  invite: (channelId, userId) ->
    opts =
      token: @apiToken
      channel: channelId
      user: userId
    SlackApi.channels.invite opts

  setPurpose: (channelId, purpose) ->
    opts =
      token: @apiToken
      channel: channelId
      purpose: purpose
    SlackApi.channels.setPurpose opts

  postMessage: (channelId, detail)->
    opts =
      token: @botToken
      channel: channelId
      as_user: false
      username: @robot.name

    SlackApi.chat.postMessage _.merge(detail, opts)

  pin: (channelId, ts)->
    opts =
      token: @botToken
      channel: channelId
      timestamp: ts
    SlackApi.pins.add opts
            
module.exports = SmExt
