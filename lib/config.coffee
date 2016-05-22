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


fs = require 'fs'
_config = null

loadConfig = ()->
  file = process.env.CONFIG_FILE
  # console.log file
  str = fs.readFileSync file, 'utf8'
  # console.log str
  _config = JSON.parse str
  _config


checkConfig = ()->
  _config or loadConfig()

getEnv = (path)->
  path = path.replace /\./g, '_'
  process.env[path.toLowerCase()]

cfg =
  get: (path)->
    data = checkConfig().config
    parts = path.split '.'
    for part in parts
      if data
        data = data[part]
      else
        data = null
        break
    if not data
      data = getEnv(path)
    data


module.exports = cfg
