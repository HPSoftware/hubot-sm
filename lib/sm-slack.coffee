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

  createRoom: (name)->
    opts =
      token: @apiToken
      name: name
    SlackApi.channels.create opts

  setTopic: (channelId, topic)->
    opts =
      token: @botToken
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
      token: @botToken
      channel: channelId
      purpose: purpose
    SlackApi.channels.setPurpose opts

  postMessage: (channelId, detail)->
    opts =
      token: @botToken
      channel: channelId
      text: detail.text
      as_user: false
      username: @robot.name

    SlackApi.chat.postMessage opts

  pin: (channelId, ts)->
    opts =
      token: @botToken
      channel: channelId
      timestamp: ts
    SlackApi.pins.add opts


module.exports = SmExt
