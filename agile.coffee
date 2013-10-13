# Description:
#   Interaction with github.
#
# Commands:
#   hubot issues - List the issues
#   hubot est - Display all open issues with estimates

_      = require 'underscore'
yaml_parser = require 'js-yaml'

# TODO: use title to group issues
# TODO: flag issues without an estimate

# https://trello.com/1/authorize?key=880bde7162f412901595af9c3a5e8a2a&name=gatabot&expiration=1day&response_type=token&scope=read,write
trello = new (require 'node-trello') '', ''
github = (require 'octonode').client ''

ghme   = github.me()
ghrepo = github.repo 'gatalabs/gataweb'

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

  robot.respond /trello (.*)$/i, ( msg ) ->
    board_id = 'Ws1IHWA9'
    lists =
      queue:    '52558bca867ab74a690011be'
      work:     '52558bca867ab74a690011bf'
      test:     '52558bca867ab74a690011c0'
      review:   '52558be89b69668336000b0b'
      done:     '52558bed338d3c065200119b'

    if lists[ msg.match[ 1 ] ]?

      trello.get "/1/lists/#{ lists[ msg.match[ 1 ] ] }/cards", ( err, cards ) ->
        if err
          console.error err
          msg.send 'error'

        for card in cards
          # TODO: should include assignee, parse out github ticket and display ticket completion
          # TODO: card.idMembers
          msg.send "#{ card.name }"

    else
      msg.send 'no list'

      ###
      # Fetches all cards on a board
      trello.get "/1/boards/#{ board_id }/cards", ( err, cards ) ->
        return console.error err if err
        console.info cards

        console.info _.filter cards, ( card ) -> card.list_id == lists[ msg.match[ 1 ] ]
      ###
