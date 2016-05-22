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




module.exports = (robot) ->
  # if not robot.sm_ext
  #   SmExt = require "../lib/sm-#{robot.adapterName}"
  #   robot.sm_ext = new SmExt(robot)
  #
  # robot.respond /create-room (.+)/i, (resp) ->
  #   p = robot.sm_ext.createRoom resp.match[1]
  #   p.then (r)->
  #     robot.logger.debug "Room created #{r.channel.id}"
  #   .catch (e) ->
  #     robot.logger.error "Room creation failed: #{e}"
