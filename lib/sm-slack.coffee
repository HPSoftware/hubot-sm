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

  buildSlackMsgFromSmError: (msg, channel, data)->
    fields = _.omitBy data.body.Incident, (v)->
      Array.isArray v
    fields = _.map fields, (v, k)->
        r =
          title: k
          value: v
          short: true

    att =
      text: "*Reason*: _#{data.body.Messages.join('\r')}_"
      fields: fields
      mrkdwn_in: ["text", "pretext"]
      color: 'warning'
    slackMsg =
      mrkdwn: true
      channel: channel
      text: msg
      attachments:[att]

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
