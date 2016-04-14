

module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

  robot.respond /create-room (.+)/i, (resp) ->
    p = robot.sm_ext.createRoom resp.match[1]
    p.then (r)->
      robot.logger.debug "Room created #{r.channel.id}"
    .catch (e) ->
      robot.logger.error "Room creation failed: #{e}"
