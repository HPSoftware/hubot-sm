_ = require 'lodash'

sendHelp = (robot, channel, msg)->
  if robot.adapterName is 'slack'
    text = _.map(msg, (m)-> "_#{m}_").join("\r\n")
    robot.emit 'slack.attachment', {channel: channel, text: text}
  else
    robot.send msg.join("\r\n")


module.exports = {
  send: sendHelp
}
