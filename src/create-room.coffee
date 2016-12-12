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
Promise =  require 'bluebird'
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
      robot.adapterName is 'slack' and /!create-room\s+(.*)/i.test(msg.text)
    (resp) ->
      robot.logger.debug('To create a room')
      # robot.logger.debug resp
      msg = resp.message
      msgObj = {}
      # cp = new CreateRoomCommandParser(msg.text)
      # cp.parse()

      roomInfo = parseRoomInfo /!create-room (.*)/i.exec(msg.text)[1]
      msgObj = _.merge({}, roomInfo)
      robot.logger.debug(msgObj)
      # format
#      channelName = msgObj.service + msgObj.id
      # we need to prefix with instance name and make sure it is less than 21
      default_ins = Config.get "sm.servers.default"
      default_endpoint = Config.get "sm.servers.#{default_ins}.endpoint"
      endpoint = "#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}"
      if default_endpoint == endpoint
        name=default_ins
      else
        servers = Config.get 'sm.servers'
        # get alias by endpoint
        name = _.findKey(servers, (v)->
          v and v.endpoint is endpoint
        )
      if not name then name = default_ins
      channelName = robot.sm_ext.formatChannelName name, msgObj.room_name
      buf = new Buffer(msgObj.docengine_url,'base64')
      docengine_url = buf.toString('utf8')
      robot.logger.debug("doc engine url is #{docengine_url}")
      robot.logger.debug('To create a new channel: ' + channelName)
      # What we do following here
      # 1. Create a new Channel based on name defined in SM
      # 2. Set Topic of the Channel
      # 3. Set Purpose of the Channel
      # 4. Invite people joining the channel, including bot
      # 5. Post a message about the incident
      # 6. Pin the message

      robot.sm_ext.createRoom(channelName)
        .then (body) ->
          robot.logger.debug(body)
          channelId = body.channel.id
          robot.e.adapter.exec(resp,'findUsersID', robot.name)
          .then (r) ->
            robot.logger.debug('find userid for:'+robot.name + ' is '+r)
            user_id = r[0]
            robot.logger.debug("now try to invite:"+user_id+" type:"+(typeof user_id)+" channelid:"+channelId)
            robot.sm_ext.invite(channelId, user_id)
              .then (body) ->
                topic = msgObj.title
                robot.logger.debug("now set topic:"+topic)
                robot.sm_ext.setTopic channelId, topic
              .then (body) ->
                purpose = "#{msgObj.description}"
                robot.logger.debug("now set purpose:"+purpose)
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
                    attachments: msgObj.attachments

                  # robot.emit 'slack.attachment', data
                  robot.logger.debug("now post the data of ticket")
                  robot.sm_ext.postMessage channelId, data
                else
                  text = "<Don't delete and unpin this>\r\nID=#{msgObj.id}\r\nSM=#{msgObj.metaInfo.server}:#{msgObj.metaInfo.port}\r\nDOCENGINE_URL=#{docengine_url}"
                  # robot.send {room:channelName}, text
                  robot.sm_ext.postMessage cannelId, text
              .then (body) ->
                robot.logger.debug("now try to pin it:"+channelId)
                robot.sm_ext.pin channelId, body.ts
              .then (body) ->
                robot.logger.debug("now try to invite other user")
                robot.e.adapter.exec(resp,'usersList')
                .then (r) ->
                  robot.logger.debug('get userlist to match the email')
                  invitees = _(r).filter((user)-> !!user.email and user.email in msgObj.users).value()
                  invitedBots = _(r).filter((user)-> user.name in msgObj.invitedBots).value()
                  invitees.push(bot) for bot in invitedBots
                  robot.logger.debug("invite peoples:"+invitees)
                  ps = _.map(invitees, (user)->
                    robot.sm_ext.invite channelId, user.id
                    robot.logger.debug("invited people:"+user.name)
                  )
                .catch (err) ->
                  robot.logger.error("when try to get usersList meet exception:"+err)
              .catch (e)->
                robot.logger.error("invite bot user meet exception:"+e)
          .catch (err) ->
            robot.logger.error("when try to findUsersID for "+robot.name+ " meet exception:"+err)
        .catch (er)->
           robot.logger.error("create room meet exception:"+er)       

  )
