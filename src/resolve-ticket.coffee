# Description:
#
# Commands:
#   sm incident resolve <id> <message> (on <ins>) - Resolve a Service Manager Incident
#
# Author:



co = require 'co'
SM = require '../lib/smworker'
Config = require '../lib/config'
Help = require '../lib/sm-help'

module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

  needRes = [
    "Need a *resolution message* when resolving a Service Manager incident",
    "Try `sm resolve incident <ID> <\"message\">`"
  ]

  robot.respond /ssm\s+resolve\s+incident\s+([\w\d]+)\s*(?:["“”']([^"”“']+)["“”'])?(?:\s*on\s+(.+))?$/i,(resp)->
    match = resp.match

    id = match[1]
    msg = match[2]
    if not msg
      Help.send robot, resp.message.room, needRes
      return
    ins = if match[3]
            match[3]
          else
            Config.get "sm.servers.default"
    endpoint = Config.get "sm.servers.#{ins}.endpoint"
    if not endpoint
      resp.reply "Unknown SM instance <#{ins}>"
      return
    user = resp.message.user

    SM.incident.resolve(id, msg, ins, "<#{user.name}|#{user.email_address}>")
      .then (r)->
        resp.reply "Incident #{id} was resolved"
      .catch (r)->
        robot.logger.debug r
        msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to resolve incident #{id}", resp.message.rawMessage.channel, r
        robot.emit 'slack.attachment', msg
    resp.reply "updating Incident #{id} on #{ins}<#{Config.get "sm.servers."+ins+".endpoint"}>....."
