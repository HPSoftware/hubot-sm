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


SM = require '../lib/smworker'
Config = require '../lib/config'
Help = require '../lib/sm-help'

module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

  robot.respond /ssm\s+get\s+incident\s+([\w\d]+)(?:\s+on\s+([\w\d]+))?/i, (resp)->
    id = resp.match[1]
    ins = resp.match[2] or Config.get "sm.servers.default"

    SM.incident.get(id, ins)
      .then (r)->
        robot.logger.debug "Success #{r}"
        msg = robot.sm_ext.formatRecord r.body.Incident
        msg.channel = resp.message.rawMessage.channel
        msg.text = "Incident `#{id}` - #{r.body.Incident.Title}"
        msg.attachments[0].text = r.body.Incident.Description.join("\r")
        robot.emit 'slack.attachment', msg
      .catch (r) ->
        robot.logger.debug r
        msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to retrieve incident #{id}", resp.message.rawMessage.channel, r
        robot.emit 'slack.attachment', msg

    resp.reply "Retrieving Incident #{id}..."
