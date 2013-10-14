# Description:
#   Layers D&D themed agile interactions on github and trello
#
# Commands:
#   dm (epi|epic) - list all quests with status (list all the features with status)
#   dm (que|quest) - view all quests (list all features)
#   dm (que|quest) (o|open) <name> - view all unslain creatures in a quest <name> (view open tasks for a feature)
#   dm (que|quest) (c|closed) <name> - view all slain creatures in a quest <name> (view closed tasks for a feature)
#   dm (mil|milestone) - view all milestones 
#   dm (mil|milestone) (inc|incomplete) - view incomplete milestones (view all past due milestones)
#   dm (mil|milestone) (c|closed) - view complete milestones (view all closed milestones)
#   dm (enc|encounter) - view all encounters (view all sprints)
#   dm (enc|encounter) (inc|incomplete) - view incomplete encounters (view all past due sprint)
#   dm (enc|encounter) (o|open) <name> - view all open creatures in an encounter <name> (view list of open tasks for sprint)
#   dm (enc|encounter) (c|closed) <name>  - view all closed creatures in an encounter  <name> (view list of closed tasks for sprint)
#   dm (enc|encounter) <name> - view all creatures for that encounter <name> (view all task from sprint)
#   dm (enc|encounter) (s|start) <name> - start encounter with <name> (start a sprint with name)
#   dm (enc|encounter) (f|finish) <name> - finish encounter with <name> (close a sprint with name)
#   dm (enc|encounter) (a|add) <creature> <encounter name> - move creature <creature> from <encounter name> (move task from backlog to sprint)
#   dm (enc|encounter) (r|remove) <creature> <encounter name> - remove creature <creature> from <encounter name> (remove task from backlog to sprint)
#   dm (enc|encounter) (st|stats) <name> - view total creature hp and total party hp 
#   dm (cre|creature) (eng|engage) <name> - player character engages creature (assign task to user)
#   dm (cre|creature) (atk|attack) <name> <hit points> <damage done> - player character attacks creature <name> with <hit points> and describes <damage done> (add hours spent and comment to task)
#   dm (cre|creature) (bl|bloodied) - view all bloodied creatures (view items marked for code review)
#   dm (eng|engage) [TARGET] - Start progress on an issue
#   dm (atk|attack) [TARGET] - Start an issue by number or class
#   dm (dmg|damage) [TARGET] - Damage a creature
#   dm (dispatch|slay) [TARGET] -
#   dm finish []
#   dm coup de grace - Finish him!
#
#   dm balance
#   dm stats [TARGET] - Display the stats of a user or creature

_ = require 'underscore'
yaml_parser = require 'js-yaml'

# TODO: use title to group issues
# TODO: flag issues without an estimate
#

# https://trello.com/1/authorize?key=3bbf777e98373409c9954efe73ed07fe&name=Dungeon Master&expiration=1day&response_type=token&scope=read,write
trello = new (require 'node-trello') '3bbf777e98373409c9954efe73ed07fe', '3a83324b9117f089dcf1c2c5083485228a8f283a9658feb7f10664157882defe'
github = (require 'octonode').client 'a11d770dc58417ff090dd83e3871edbc3702fec6'

ghme   = github.me()
ghrepo = github.repo 'amccausl/mongoose-dragon'

yaml_regex = /---([^-]*)\.\.\./

module.exports = ( robot ) ->
  robot.respond /engage/i, ( msg ) ->
    msg.send 'engage triggered'

  robot.respond /attack/i, ( msg ) ->
    msg.send 'attack triggered'

  robot.respond /damage/i, ( msg ) ->
    msg.send 'damage triggered'

  robot.respond /dispatch/i, ( msg ) ->
    msg.send 'dispatch triggered'

  robot.respond /finish/i, ( msg ) ->
    msg.send 'finish triggered'

  robot.respond /coup de grace/i, ( msg ) ->
    msg.send 'coup de grace'

  robot.respond /encounter/i, ( msg ) ->
    msg.send 'encounter triggered'

  robot.respond /issues$/i, ( msg ) ->
    ghrepo.issues ( err, issues ) ->
      return msg.send 'error' if err
      return msg.send 'No Issues' if ! issues

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
