#_ = require('lodash')
#IncidentMangement = require('../src/SMUtil')
#S = require('string')
#api = require '../src/slack_web_api'
#Promise = require 'bluebird'
co = require 'co'
SM = require '../lib/smworker'
Config = require '../lib/config'


# Bot command - resolve SM ticket with proposed solution
#Syntax:
#   @motieph: resolve IM10392 –s [solution]
module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)
  robot.respond /sm\s+resolve\s+incident\s+([\w\d]+)\s*(["“']([^"“']+)["“'])?(\s*on\s+(.+))?/i,(resp)->
    match = resp.match
    robot.logger.debug match
    id = match[1]
    msg = match[3]
    if not msg
      msg = """
      Need a resolution message when resolving an incident.
      ------
      Try sm resolve incident <ID> <"message">
      """
      resp.reply msg
      return
    ins = if match[5]
            ins
          else
            Config.get "sm.servers.default"
    SM.incident.resolve(id, msg, ins)
      .then (r)->
        resp.reply "Incident #{id} was resolved"
