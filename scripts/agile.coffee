# Description:
#   Layers D&D themed agile interactions on github and trello
#
# Commands:
#   dm (epi|epic) - list all quests with status (list all the features with status)
#   dm (que|quest) - view all quests (list all features)
#   dm (que|quest) (o|open) <name> - view all unslain creatures in a quest (view open tasks for a feature <name>)
#   dm (que|quest) (c|closed) <name> - view all slain creatures in a quest (view closed tasks for a feature <name>)
#   dm (mil|milestone) - view all milestones
#   dm (mil|milestone) (inc|incomplete) - view incomplete milestones (view all past due milestones)
#   dm (mil|milestone) (c|closed) - view complete milestones (view all closed milestones)
#   dm (enc|encounter) - view all encounters (view all sprints)
#   dm (enc|encounter) (inc|incomplete) - view incomplete encounters (view all past due sprint)
#   dm (enc|encounter) (o|open) <name> - view all open creatures in an encounter (view list of open tasks for sprint <name>)
#   dm (enc|encounter) (c|closed) <name>  - view all closed creatures in an encounter (view list of closed tasks for sprint <name>)
#   dm (enc|encounter) (cr|creatures) <name> - view all creatures for that encounter (view all task from sprint <name>)
#   dm (enc|encounter) (s|start) <name> - start named encounter (start a sprint <name>)
#   dm (enc|encounter) (f|finish) <name> - finish named encounter (close a sprint <name>)
#   dm (enc|encounter) (a|add) <creature> <encounter name> - move creature from encounter (move task <creature>  from backlog to sprint <encounter name>)
#   dm (enc|encounter) (r|remove) <creature> <encounter name> - remove creature from (remove task <creature> from backlog to sprint <encounter name>)
#   dm (enc|encounter) (st|stats) <name> - view total creature hp and total party hp
#   dm (cre|creature) (eng|engage) <name> - player character engages creature (assign task to user)
#   dm (cre|creature) (atk|attack) <name> <hit points> <damage done> - player character attacks creature with hit point and damage (add hours spent <hit points> and comment<damage done> to task <name>)
#   dm (cre|creature) (atk|attack) (crit|critical) <name> <damage done> - player character attacks creature critical hit and describes (add comment<damage done> and label code-review to task <name>)
#   dm (cre|creature) (bl|bloodied) - view all bloodied creatures (view items marked for code review)
#   dm (cre|creature) (un|unconscious) <name> - creature is unconscious (label task <name> for testing)
#   dm (cre|creature) (re|revive) <name> - revive creature (task <name> failed code review or testing)
#   dm (cre|creature) (fl|flee) <name> - flee creature encounter (move task <name> to triage)
#   dm (cre|creature) (cdg|coupdegrace) <name> - kill the creature (mark task <name> as closed)
#   dm (cre|creature) (cl|combatlog) <name> - view creature combat log (view task <name> comments)
#   dm (par|party) - view party information
#   dm (par|party) <name> - view stats for party member <name>

_ = require 'underscore'
yaml_parser = require 'js-yaml'

label =
  FEATURE: 'dm: feature'

state =
  OPEN:   'open'
  CLOSED: 'closed'

# TODO: use title to group issues
# TODO: flag issues without an estimate
#

# https://trello.com/1/authorize?key=3bbf777e98373409c9954efe73ed07fe&name=Dungeon Master&expiration=1day&response_type=token&scope=read,write
trello = new (require 'node-trello') '3bbf777e98373409c9954efe73ed07fe', '3a83324b9117f089dcf1c2c5083485228a8f283a9658feb7f10664157882defe'
github = (require 'octonode').client 'a11d770dc58417ff090dd83e3871edbc3702fec6'

ghme   = github.me()
ghrepo = github.repo 'amccausl/mongoose-dragon'

yaml_regex = /---([^-]*)\.\.\./

parseYaml = ( issue ) ->
  meta = {}
  parse = yaml_regex.exec issue.body
  if parse
    for key, value of yaml_parser.safeLoad parse[ 1 ]
      key = key.toLowerCase().replace( /\ /g, '_' )
      meta[ key ] = value

  return meta

renderIssues = ( issues, msg ) ->
  return msg.send 'No Issues' if ! issues
  for issue in issues
    renderIssue issue, msg

renderIssue = ( issue, msg ) ->
  console.info parseYaml issue
  msg.send "\##{ issue.number } #{ issue.title }:\n#{ issue.body }"

module.exports = ( robot ) ->
  robot.respond /epi|epic/i, ( msg ) ->
    msg.send 'list all quests with status (list all the features with status)'

  robot.respond /(que|quest)$/i, ( msg ) ->
    msg.send 'view all quests (list all features)'
    ghrepo.issues null, null, { labels: label.FEATURE }, ( err, issues ) ->
      return msg.send 'error' if err
      renderIssues issues, msg

  robot.respond /(que|quest) (o|open) (.+)$/i, ( msg ) ->
    msg.send "view all unslain creatures in a quest (view open tasks for a feature #{ msg.match[ 3 ] })"
    # by 'feature' label in github'

  robot.respond /(que|quest) (c|closed) (.+)$/i, ( msg ) ->
    msg.send 'view all unslain creatures in a quest (view closed tasks for a feature <name>)'
    ghrepo.issues null, null, { labels: label.FEATURE, state: state.CLOSED }, ( err, issues ) ->
      return msg.send 'error' if err
      renderIssues issues, msg

  robot.respond /(mil|milestone)$/i, ( msg ) ->
    msg.send 'view all milestones'
    ghrepo.milestones ( err, milestones ) ->
      return msg.send 'error' if err
      console.info('milestones', milestones)
      milestoneList = {}
      for milestone in milestones
        msg.send "\##{ milestone.number } #{ milestone.title }:\n#{ milestone.description ? '' }"

  robot.respond /(mil|milestone) (inc|incomplete)$/i, ( msg ) ->
    msg.send 'view incomplete milestones (view all past due milestones)'

  robot.respond /(mil|milestone) (c|closed)$/i, ( msg ) ->
    msg.send 'view complete milestones (view all closed milestones)'

  robot.respond /(enc|encounter)$/i, ( msg ) ->
    msg.send 'view all encounters (view all sprints)'

  robot.respond /(enc|encounter) (inc|incomplete)$/i, ( msg ) ->
    msg.send 'view incomplete encounters (view all past due sprint)'

  robot.respond /(enc|encounter) (o|open) (.+)$/i, ( msg ) ->
    msg.send "view all open creatures in an encounter (view list of open tasks for sprint #{ msg.match[ 3 ] })"

  robot.respond /(enc|encounter) (c|closed) (.+)$/i, ( msg ) ->
    msg.send 'view all closed creatures in an encounter (view list of closed tasks for sprint <name>)'

  robot.respond /(enc|encounter) (cr|creatures) (.+)$/i, ( msg ) ->
    msg.send 'view all creatures for that encounter (view all task from sprint <name>)'

  robot.respond /(enc|encounter) (s|start) (.+)$/i, ( msg ) ->
    msg.send 'start named encounter (start a sprint <name>)'

  robot.respond /(enc|encounter) (f|finish) (.+)$/i, ( msg ) ->
    msg.send 'finish named encounter (close a sprint <name>)'

  robot.respond /(enc|encounter) (a|add) (.+) (.+)$/i, ( msg ) ->
    msg.send 'move creature from encounter (move task <creature>  from backlog to sprint <encounter name>)'

  robot.respond /(enc|encounter) (r|remove) (.+) (.+)$/i, ( msg ) ->
    msg.send 'remove creature from (remove task <creature> from backlog to sprint <encounter name>)'

  robot.respond /(enc|encounter) (st|stats) (.+)$/i, ( msg ) ->
    msg.send 'view total creature hp and total party hp'

  robot.respond /(cre|creature) (eng|engage) (.+)$/i, ( msg ) ->
    msg.send 'player character engages creature (assign task to user)'

  robot.respond /(cre|creature) (atk|attack) (.+) (.+) (.+)$/i, ( msg ) ->
    msg.send 'player character attacks creature with hit point and damage (add hours spent <hit points> and comment<damage done> to task <name>)'

  robot.respond /(cre|creature) (atk|attack) (crit|critical) (.+) (.+)$/i, ( msg ) ->
    msg.send 'player character attacks creature critical hit and describes (add comment<damage done> and label code-review to task <name>)'

  robot.respond /(cre|creature) (bl|bloodied)$/i, ( msg ) ->
    msg.send 'view all bloodied creatures (view items marked for code review)'

  robot.respond /(cre|creature) (un|unconscious) (.+)$/i, ( msg ) ->
    msg.send 'creature is unconscious (label task <name> for testing)'

  robot.respond /(cre|creature) (re|revive) (.+)$/i, ( msg ) ->
    msg.send 'revive creature (task <name> failed code review or testing)'

  robot.respond /(cre|creature) (fl|flee) (.+)$/i, ( msg ) ->
    msg.send 'flee creature encounter (move task <name> to triage)'

  robot.respond /(cre|creature) (cdg|coup de grace) (.+)$/i, ( msg ) ->
    msg.send 'kill the creature (mark task <name> as closed)'

  robot.respond /(cre|creature) (cl|combat log) (.+)$/i, ( msg ) ->
    msg.send 'view creature combat log (view task <name> comments)'

  robot.respond /(par|party)$/i, ( msg ) ->
    msg.send 'view party information'
    # /repos/:repo/contributors
    # if in encounter, display combat
    ghrepo.contributors ( err, contributors ) ->
      return msg.send 'error' if err

      for contributor in contributors
        console.info contributor

  robot.respond /(par|party) (.+)$/i, ( msg ) ->
    msg.send 'view stats for party member <name>'

  robot.respond /issues$/i, ( msg ) ->
    ghrepo.issues null, null, { labels: 'failed' }, ( err, issues ) ->
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
