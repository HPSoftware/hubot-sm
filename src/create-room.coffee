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
  # Invite users to channel
  inviteUsers = (channel, invitees)->
    for invitee in invitees
      # robot.logger.debug invitee.name, invitee.id
      robot.logger.debug 'To invite ' + invitee.id + ' to channel: ' + channel
      robot.http('https://slack.com/api/channels.invite?token=' + process.env.SLACK_APP_TOKEN + '&channel=' + channel + '&user=' + invitee.id)
        .get() (err, resp, body) ->
          robot.logger.debug body

  # Pin message to channel
  pinMessage = (channel, ts)->
    robot.http('https://slack.com/api/pins.add?token=' + process.env.SLACK_APP_TOKEN+'&channel='+channel+"&timestamp="+ts)
      .get() (err, resp, body) ->

  # create a channel


  # We need to use robot.listen to track bot sent message. message subtype: 'bot_message'
  robot.listen(
    (msg) ->
      # This is bit slack specific
      # robot.logger.debug 'receive message'
      # robot.logger.debug msg
      robot.adapterName is 'slack' and /!create-room (.*)/i.test(msg.rawText)

    (resp) ->
      # robot.logger.debug 'To execute bot listener'
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
      channelName = msgObj.room_name
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

      # robot.logger.debug('https://slack.com/api/channels.create?token=' + process.env.SLACK_APP_TOKEN + '&name=' + channelName)
      # TODO: chain this using promise
      robot.sm_ext.createRoom(channelName)
        .then (body) ->
          channelId = body.channel.id
          user = robot.brain.userForName robot.name
          if not user
            Promise.reject("not find user")
          else
            robot.sm_ext.invite(channelId, user.id)
              .then (body)->
                topic = msgObj.title
                robot.sm_ext.setTopic channelId, topic
              .then (body) ->
                purpose = "#{msgObj.description}"
                robot.sm_ext.setPurpose channelId, purpose
              .then (body) ->
                text = "<Don't delete and unpin this>\r\nID=#{msgObj.id}\r\nSM=#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}\r\nDOCENGINE_URL=#{docengine_url}"
                robot.sm_ext.postMessage channelId, {
                  text: text
                }
              .then (body)->
                robot.sm_ext.pin channelId, body.ts


#       robot.http('https://slack.com/api/channels.create?token=' + process.env.SLACK_APP_TOKEN + '&name=' + channelName)
#         .get() (err, resp, body) ->
#           if err
#             msg.send 'Unable to create room: ' + channelName
#           else
#             bodyObj = JSON.parse body
#             # roomMetaInfo['channelId'] = bodyObj.channel.id
#             # robot.brain.set channelName, roomMetaInfo
#             if bodyObj.ok
#               robot.logger.debug 'Room: ' + channelName + ' created'
# #              converged_info = _.extend(bodyObj,{msgObj:msgObj})
# #              robot.brain.set bodyObj.channel.name converged_info
#               topic = msgObj.title
#               robot.http('https://slack.com/api/channels.setTopic?token=' + process.env.SLACK_APP_TOKEN + '&channel=' + bodyObj.channel.id + '&topic=' + topic)
#                 .get() (err, resp, body) ->
#                   robot.logger.debug body
#
#               purpose = msgObj.description
#
#               robot.http('https://slack.com/api/channels.setPurpose?token=' + process.env.SLACK_APP_TOKEN + '&channel=' + bodyObj.channel.id + '&purpose=' + purpose)
#                 .get() (err, resp, body) ->
#                   buf = new Buffer(msgObj.docengine_url,'base64')
#                   docengine_url = buf.toString('utf8')
#                   robot.logger.debug "doc engine url is #{docengine_url}"
#
#                   text = "<Don't delete this>\r\nID=#{msgObj.id}\r\nSM=#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}\r\nDOCENGINE_URL=#{docengine_url}"
#                   robot.http('https://slack.com/api/chat.postMessage?token=' + process.env.SLACK_APP_TOKEN+'&channel='+bodyObj.channel.id+"&text="+Querystring.escape(text)+"&username=motieph&as_user=true")
#                     .get() (err, resp, body)->
#                       if not err
#                         rObj = JSON.parse body
#                         if not rObj.ok
#                           robot.logger.debug rObj
#                         else
#                           ts = rObj.ts
#                           pinMessage bodyObj.channel.id, ts
#                           # to invite users
#                           invitees = _(robot.brain.users()).filter((user)-> !!user.email_address and user.email_address in msgObj.users).value()
#                           bot = robot.brain.userForName('motieph')
#                           invitees.push bot
#                           inviteUsers bodyObj.channel.id, invitees
#             else
#               robot.logger.info 'Unable to create room: ' + body
  )

  # close room
  # robot.hear /close room/i, (res)->
  #   # robot.logger.debug res
  #   res.reply "Got it, working on it"
  #   # metaInfo = robot.brain.get res.room
  #   res.reply "... attaching messages to SM ticket"
  #   #
  #   res.reply "closing and archiving room"
  #
  #   robot.http('https://slack.com/api/channels.archive?token=' + process.env.SLACK_APP_TOKEN+"&channel=#{res.message.rawMessage.channel}")
  #     .get() (err, resp, body) ->
  #       robot.logger.debug body
