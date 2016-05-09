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
