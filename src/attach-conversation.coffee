_ = require('lodash')
IncidentMangement = require('../lib/SMUtil')
async = require 'async'
S = require('string')
Config = require '../lib/config'

# Bot command - resolve SM ticket with proposed solution
#Syntax:
#   @motieph: attach conversation to IM10392
module.exports = (robot, callback) ->
  robot.logger.debug Config.get('sm.servers.default')
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)
  # Method to resolve user name from
  resolveUser = (text)->
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
    text

  robot.respond /sm\s+attach\s+incident\s*([\w\d]+)\s*(on (.+))?/i, (res)->
    id = res.match[1]
    robot.logger.debug res.match
    ins = res.match[3] or Config.get "sm.servers.default"

    robot.logger.debug "SM instance is #{ins}"
    serverEndpoint = Config.get("sm.servers.#{ins}.endpoint")
    [server, port] = serverEndpoint.split ":"
    account = Config.get("sm.servers.#{ins}.account")
    robot.logger.debug "To attach conversation to #{id} on #{serverEndpoint}"
    latest_ts = 0
    result = []
    has_more = true
    # TODO: this is Slack specific
    channel = res.message.rawMessage.channel
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
        robot.logger.debug "PASSWORD:#{Config.get("sm.servers.#{ins}.password")}"
        # robot.logger.debug "Doc Engine URL : #{docengine_url}"
        robot.logger.debug "incident id is #{id}"
        robot.logger.debug "message count is #{messages.length}"
        texts = []
        texts.push(resolveUser(m.text)) for m in messages
        texts = texts.reverse()

        incident = new IncidentMangement(server, port, account.trim(), Config.get("sm.servers.#{ins}.password").trim())
        incident.incident_id = id
        incident.update
          "Incident":
            "review.detail": ["attach conversation"],
            "JournalUpdates": texts
        res.reply 'Attached'
        # res.reply "Ticket updated, you can review ticket in SM via #{docengine_url}"
        cb(null)
    ])
