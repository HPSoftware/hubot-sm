# hubot-sm

A hubot script for Service Manager ChatOps integration

## Installation

In hubot project repo, run:

`npm install hubot-sm --save`

Then add **hubot-sm** to your `external-scripts.json`:

```json
[
  "hubot-sm"
]
```

See test hubot project https://github.com/HPSoftware/sm-chatops-boot (TODO)

## Commands support

Main commands are supported

1. Attach conversation to Incident
  * `sm incident attach <ID> on <ins>`
1. Resolve an incident
  * `sm incident resolve <ID> <msg> on <ins>`

### Self discovery

Show what have supported so far
```
sm
```
And it will print major SM modules supported
```
sm incident
```
User can continue discover by typing `sm incident` and it will print out
```
sm incident resolve ...
sm incident attach-conversation ...
```

## Misc

### Config
User put configuration in a json file, see example https://github.com/HPSoftware/sm-chatops-boot/blob/master/config.json (todo)
```json
{
  "config":{
    "sm":{
      "servers":{
        "default":"test",
        "test":{
          "endpoint":"16.187.186.51:13080",
          "account":"System.Admin"
        }
      }
    }
  }
}
```
So in the command, user can specify
```
sm incident attach IM092
sm incident attach IM928 on test
```
Two commands are equivalent.
