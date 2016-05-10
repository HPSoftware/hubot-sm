#
_ = require 'lodash'
# To be removed
module.exports = (robot, callback) ->

  helpIncident = [
    "Hi, you can do a lots on Service Manager Incident Management module",
    "* `sm resolve incident [ID] [resolve message] (on [sm instance])` - Resolve a Service Manager incident",
    "* `sm attach incident [ID] (on [sm instance])` - Attach conversation in this channel to Service Manager incident"
  ]

  helpChange = [
    "Hi, you can do a lots on Service Manager Change Management module",
    "* `sm approve change [ID] [message] (on [sm instance])` - Approve a Service Manager change"
  ]

  helpSm = [
    "Hi, use `sm` to access Service Manager. Try one of following to continue...",
    "* `sm incident` - to access Service Manager Incident Management module",
    "* `sm change` - to access Service Manager Change Management module"
  ]

  helpUnknown = [
    "Hi, I don't get that. Try use `sm` to see what Service Manager can do"
  ]

  helps =
    incident: helpIncident
    change: helpChange
    sm: helpSm

  sendHelp = (channel, msg)->
    if robot.adapterName is 'slack'
      text = _.map(msg, (m)-> "_#{m}_").join("\r\n")
      robot.emit 'slack.attachment', {channel: channel, text: text}
    else
      robot.send msg.join("\r\n")

  help = (hint, res, command)->
    msg = helps[hint]
    if msg
      # res.send msg
      sendHelp res.message.room, msg
    else
      sendHelp res.message.room, helpUnknown

  robot.respond /ssm\s*$/i, (res)->
    help 'sm', res

  # robot.respond /sm\s+(\w+)/i, (res)->
  #   robot.logger.debug "Try to help with #{res.match[0]}"
  #   name = res.match[1]
  #   switch name
  #     when 'incident' then help 'incident', res
  #     when 'change' then help 'change', res
  #     else help 'unknown', res, res.match[0]
