fs = require 'fs'
_config = null

loadConfig = ()->
  file = process.env.CONFIG_FILE
  # console.log file
  str = fs.readFileSync file, 'utf8'
  # console.log str
  JSON.parse str


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
