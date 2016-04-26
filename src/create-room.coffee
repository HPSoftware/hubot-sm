# Description:
#   Command to create a room
#   This command is sent by SM to bot.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#

_ = require('lodash')
Querystring = require('querystring')
Config = require '../lib/config'
BaseRoomInfo =
  server:'localhost'
  port:'13080'
  service: ""
  id: '' # incident id
  title: ''
  description: ''
  users: [] # invitees who are already exists in Slack with same email address
  affected_service:null
  affected_ci: null

module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

  parseRoomInfo = (text)->
    JSON.parse new Buffer(text, 'base64').toString('utf8')

  # We need to use robot.listen to track bot sent message. message subtype: 'bot_message'
  robot.listen(
    (msg) ->
      # This is bit slack specific
      robot.logger.debug "check CreateRoom- Listen message: #{msg.text}"
      # robot.logger.debug msg
      robot.adapterName is 'slack' and /!create-room\s+(.*)/i.test(msg.rawText)
    (resp) ->
      robot.logger.debug 'To create a room'
      # robot.logger.debug resp
      msg = resp.message
      msgObj = {}
      # cp = new CreateRoomCommandParser(msg.rawText)
      # cp.parse()

      roomInfo = parseRoomInfo /!create-room (.*)/i.exec(msg.rawText)[1]
      msgObj = _.merge({}, roomInfo)
      robot.logger.debug msgObj
      # format
#      channelName = msgObj.service + msgObj.id
      # we need to prefix with instance name and make sure it is less than 21
      servers = Config.get 'sm.servers'
      endpoint = "#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}"
      # get alias by endpoint
      name = _.findKey(servers, (v)->
        v and v.endpoint is endpoint
      )
      if not name then name = endpoint
      channelName = robot.sm_ext.formatChannelName name, msgObj.room_name
      # channelName = msgObj.room_name
      buf = new Buffer(msgObj.docengine_url,'base64')
      docengine_url = buf.toString('utf8')
      robot.logger.debug "doc engine url is #{docengine_url}"
      robot.logger.debug 'To create a new channel: ' + channelName
      # What we do following here
      # 1. Create a new Channel based on name defined in SM
      # 2. Set Topic of the Channel
      # 3. Set Purpose of the Channel
      # 4. Invite people joining the channel, including bot
      # 5. Post a message about the incident
      # 6. Pin the message

      robot.sm_ext.createRoom(channelName)
        .then (body) ->
          channelId = body.channel.id
          user = robot.brain.userForName robot.name
          if not user
            Promise.reject("can not find bot user")
          else
            robot.sm_ext.invite(channelId, user.id)
              .then (body) ->
                topic = msgObj.title
                robot.sm_ext.setTopic channelId, topic
              .then (body) ->
                purpose = "#{msgObj.description}"
                robot.sm_ext.setPurpose channelId, purpose
              .then (body) ->
                # TODO: replace this with robot.emit 'slack.attachment'
                if robot.adapterName is 'slack'
                  # att =
                  #   fallback: "Major incident <#{msgObj.id}> - #{msgObj.title}"
                  #   color: "danger",
                  #   title: "Major incident <#{msgObj.id}> - #{msgObj.title}"
                  #   title_link: docengine_url
                  #   text: msgObj.description
                  #   fields: [
                  #     {
                  #       title: "Status",
                  #       value: msgObj.Status
                  #       short: true
                  #     }
                  #   ]
                  data =
                    text: msgObj.description,
                    attachments:[msgObj.attachments]

                  # robot.emit 'slack.attachment', data
                  robot.sm_ext.postMessage channelId, data
                else
                  text = "<Don't delete and unpin this>\r\nID=#{msgObj.id}\r\nSM=#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}\r\nDOCENGINE_URL=#{docengine_url}"
                  # robot.send {room:channelName}, text
                  robot.sm_ext.postMessage cannelId, text
              .then (body) ->
                robot.sm_ext.pin channelId, body.ts
              .then (body) ->
                invitees = _(robot.brain.users()).filter((user)-> !!user.email_address and user.email_address in msgObj.users).value()
                ps = _.map(invitees, (user)->
                  robot.sm_ext.invite channelId, user.id
                )
              .catch (body)->
                robot.logger.debug body


  )
