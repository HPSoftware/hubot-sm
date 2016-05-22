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
#   Update a Service Manager Incident
# Commands:
#   sm incident update <id> field=value field1=value1
#

SM = require '../lib/smworker'
Config = require '../lib/config'
Help = require '../lib/sm-help'
# To be removed
module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

  robot.respond /ssm\s+update\s+incident(.*)/i, (resp)->
    params = resp.match[1]
    #check id
    m = /([\d\w]+)(.*)/i.exec params
    id = m[1] if m?
    if not id
      Help.send robot, resp.message.room, ["Please specify an Incident `ID`"]
      return
    params = m[2].trim()
    if not params
      Help.send robot, resp.message.room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats"]
      return

    m = /(.*)?on\s+([\w\d]+)$/i.exec params
    ins = if m
            params = m[1]
            m[2]
          else
            Config.get "sm.servers.default"

    # check instance
    data = Config.get "sm.servers.#{ins}"
    if not data
      Help.send robot, resp.message.room, ["Please specify a validate Service Manager Instance name"]
      return
    if not params
      Help.send robot, resp.message.room, ["Can not update with nothing", "Please specify what you want to update in `field`=`value` formats"]
      return


    # Clean up utf8 quotations
    params = params.replace  /[\u201C|\u201D]/g, '"'
    params = params.replace /[\u2019|\u2018]/g, "'"
    reg = /([\w\d\.]+)=(?:(?:'([^']+)')|(?:"([^"]+)")|(\S+))/gi
    m = reg.exec params
    keyValues = {}
    while(m)
      # console.log m
      value = m[2] or m[3] or m[4]
      keyValues[m[1]] = value
      m = reg.exec params
    robot.logger.debug "Update Incident data"
    robot.logger.debug keyValues

    SM.incident.update(id, keyValues, ins)
      .then (r)->
        robot.logger.debug r
        resp.reply "Incident #{id} updated"
      .catch (r) ->
        robot.logger.debug r
        msg = robot.sm_ext.buildSlackMsgFromSmError "Failed to update incident #{id}", resp.message.rawMessage.channel, r
        robot.emit 'slack.attachment', msg

    resp.reply "Updating Incident #{id} on #{ins}<#{Config.get "sm.servers."+ins+".endpoint"}>....."
