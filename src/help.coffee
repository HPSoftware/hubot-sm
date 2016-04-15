#
module.exports = (robot, callback) ->
  helpIncident = """
  You can take following actions on Service Manager Incident
  ------------
  sm resolve incident [ID] [resolve message] (on [sm instance])
  sm attach incident [ID] (on [sm instance])
  """

  helpChange = """
  You can take following actions on Service Manager Change
  ---------
  sm approve change [ID] [message] (on [sm instance])
  """

  helpSm = """
  Service Manager  [sm] support following modules
  --------------
    sm incident
    sm change
  --------------
  Try each command to get detail information
  """


  helps =
    incident: helpIncident
    change: helpChange
    sm: helpSm

  help = (hint, res, command)->
    msg = helps[hint]
    if msg
      res.send msg
    else
      "Unknown command '#{command}', try sm"

  robot.respond /sm\w*$/i, (res)->
    help 'sm', res

  robot.respond /sm\s+(\w+)/i, (res)->
    name = res.match[1]
    switch name
      when 'incident' then help 'incident', res
      when 'change' then help 'change', res
      else help 'unknown', res, res.match[0]
