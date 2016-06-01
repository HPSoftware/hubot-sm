### Skills required

Before you start to develop your own SM-Hubot integration feature, make sure that you have already advanced knowledge and skills in the following areas:

Service Manager Process Designer
Service Manager JavaScript
CoffeeScript, Hubot, and Hubot-Slack
Slack API. You are recommended to have a good understanding of the concepts of [Incoming Hook API](https://api.slack.com/incoming-webhooks), and [message formatting](https://api.slack.com/docs/formatting).


### Check out the sm-hubot project

Check out is project from here. related changes are placed under the hubot-sm folder.

You can refer to the Service Manager ChatOps Administrator and User Guide on [HPE Live Network](https://hpln.hpe.com/product/chatops/) to set up your Hubot environment.

We strongly recommend you to create a new slack team for your development and testing.

### Learn about Hubot and Hubot-Slack

Our hubot-sm scripts heavily rely on two open-source projects: hubot and hubot-slack.

We strongly recommend you to familiarize yourself with the hobot/slack object model and the API methods before you start to develop your own Hubot scripts.

### SM Hubot Script Developer Guide

SM ChatOps allows developers to create their own Hubot scripts to extend its functionality. For example, developers can create a new command that enables users to close incidents from Slack in an automated way.

This guide provides simple guidelines on how developers can achieve this.

### Add a new command in hubot-sm

You can add a new command in hubot-sm. For example, you can add a command (sm close incident) to let the SM bot close an incident from Slack.

SM ChatOps contains the following scripts:

lib/*.coffee

All utility scripts are placed in the lib folder.

src/*.coffee

All Hubot scripts that conform to the protocol stack of hubot-slack integrations are placed here. For example: create-room.coffee is used to execute the "create war room" function.

The typical steps to add a new command are as follows:

- Add robot.respond to correlate to an event listener that waits to hear a specific key word or pattern.
- If the word or pattern matches, it will enter a code block to add your handlers.
The following is a sample script to implement the 'sm close incident' command.
```js
SM = require '../lib/smworker'
Config = require '../lib/config'
Help = require '../lib/sm-help'

module.exports = (robot) ->
  if not robot.sm_ext
    SmExt = require "../lib/sm-#{robot.adapterName}"
    robot.sm_ext = new SmExt(robot)

   robot.respond /sm\s+close\s+incident\s+([\w\d]+)\s*(?:["“”']([^"”“']+)["“”'])?(?:\s*on\s+(.+))?$/i,(resp)->
    match = resp.match

    id = match[1]
    closure_code = match[2]

    ins = if match[3]
            match[3]
          else
            Config.get "sm.servers.default"
    endpoint = Config.get "sm.servers.#{ins}.endpoint"
    if not endpoint
      resp.reply "Unknown SM instance <#{ins}>"
      return
    user = resp.message.user

    SM.incident.close(id, closure_code, ins, "<#{user.name}|#{user.email_address}>")
      .then (r)->
        resp.reply "Incident #{id} was closed"
      .catch (r)->
        robot.logger.debug r
        resp.reply "Failed to close Incident #{id} - #{r.body.Messages[0]}"
    resp.reply "closing Incident #{id} on #{ins}<#{Config.get "sm.servers."+ins+".endpoint"}>....."
 ```
