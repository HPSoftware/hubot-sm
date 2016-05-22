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
#
# Commands:
#   sm incident resolve <id> <message> (on <ins>) - Resolve a Service Manager Incident
#
# Author:


# To be removed
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
