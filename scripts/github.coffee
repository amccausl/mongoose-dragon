# Description:
#   Interaction with github.
#
# Commands:
#   hubot issues - List the issues
#   hubot est - Display all open issues with estimates

_      = require 'underscore'
yaml_parser = require 'js-yaml'

# TODO: yaml parsing
# TODO: use title to group issues
# TODO: flag issues without an estimate

github = require 'octonode'

client = github.client '0c187932c7276fa6e4c3b947938cb0289bf9e846'
ghme   = client.me()
ghrepo = client.repo 'gatalabs/gataweb'

yaml_regex = /---([^-]*)\.\.\./

module.exports = ( robot ) ->
  robot.respond /issues$/i, ( msg ) ->
    ghrepo.issues ( err, issues ) ->
      return msg.send 'error' if err

      for issue in issues
        parse = yaml_regex.exec issue.body
        if parse
          for key, value of ( yaml_parser.safeLoad parse[ 1 ] )
            issue[ key.toLowerCase() ] = value

      sum = 0

      for milestone, issues of ( _.groupBy issues, ( issue ) -> issue.milestone?.title )
        msg.send milestone ? 'No Milestone'
        milestone_sum = 0

        section = undefined
        for issue in ( _.sortBy issues, ( issue ) -> issue.title )
          estimate = issue.estimate || issue.estimation || ''
          milestone_sum += parseFloat estimate || 0

          segments = issue.title.split ': '
          if segments.length > 1
            new_section = segments.shift()
            title = segments.join ': '

            if new_section != section
              msg.send "  #{ new_section }:"
              section = new_section
            msg.send "    \##{ issue.number } #{ title } [#{ estimate }]"

          else
            msg.send "  \##{ issue.number } #{ issue.title } [#{ estimate }]"

        msg.send "  Total: #{ milestone_sum }d"
        sum += milestone_sum

      ###
      for issue in issues
        msg.send 'issue'
        msg.send issue.title
        msg.send issue.body
        parse = yaml_regex.exec issue.body
        if parse
          console.info yaml_parser.safeLoad parse[ 1 ]
        else
          msg.send 'no estimate'
      ###

