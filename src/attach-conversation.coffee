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

  listPinMessages = (channel, callback) ->
    robot.http('https://slack.com/api/pins.list?token=' + process.env.SLACK_APP_TOKEN + '&channel=' + channel)
      .get() (err, resp, body) ->
        if err
          callback err
        else
          callback null, JSON.parse(body)

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
        # res.reply "Ticket updated, you can review ticket in SM via #{docengine_url}"
        cb(null)
    ])

  robot.hear /attach conversation to (.*)/i,(res)->
    # command='attach conversation to '
    docengine_url = ""
    # msg = res.envelope.message.text.replace("@#{process.env.ROBOT}:",'').trimLeft()
    # groups = msg.match /^attach conversation to (.*)/i
    incident_id = res.match[1]
    room = res.envelope.room
    channel = res.message.rawMessage.channel
    listPinMessages channel, (err, body)->
      if body.ok

        for item in body.items
          if item.type is 'message'

            text = S(item.message.text).unescapeHTML().s
            match = /<.+>[\r\n]+ID=([\d\w]+)[\r\n]+SM=(.+)[\r\n]+DOCENGINE_URL=<(.+)>/mgi.exec text
            robot.logger.debug "Match result of #{text} is #{match}"
            if not match
              continue
            s = match[2]
            [server,port] = s.split(':')
            docengine_url = match[3]
            has_more = true
            latest_ts = 0
            token  = process.env.SLACK_APP_TOKEN
            result = []


            async.waterfall([
              (cb)->
                async.whilst(
                  ()->  has_more
                  (cb1)->
                    robot.http("https://slack.com/api/channels.history?token=#{token}&channel=#{channel}&count=1000&latest=#{latest_ts}")
                    .get() (err, resp, body) ->
                      r = JSON.parse(body)
                      has_more = r.has_more
                      result = _.concat(result, r.messages)
                      latest_ts = _.last(r.messages).ts if r.messages and r.messages.length > 1
                      cb1(null)

                  (err)->
                    cb(null, result)
                )
              (messages,cb)->
                robot.logger.debug "server:#{server}"
                robot.logger.debug "port:#{port}"
                robot.logger.debug "user:#{process.env.USER}"
                robot.logger.debug "PASSWORD:#{process.env.PASSWORD}"
                robot.logger.debug "Doc Engine URL : #{docengine_url}"
                robot.logger.debug "incident id is #{incident_id}"
                robot.logger.debug "message count is #{messages.length}"
                texts = []
                texts.push(resolveUser(m.text)) for m in messages
                texts = texts.reverse()

                incident = new IncidentMangement(server, port, process.env.USER, process.env.PASSWORD)
                incident.incident_id = incident_id
                incident.update
                  "Incident":
                    "review.detail": ["attach conversation"],
                    "JournalUpdates": texts
                res.reply "Ticket updated, you can review ticket in SM via #{docengine_url}"
                cb(null)
            ])
