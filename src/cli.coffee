# Startup script
# =================================================
# This file is used to manage the whole build environment.
#
# ### Main routine
#
# This file defines the command line interface with the defined commands. They
# will be run in parallel as possible.
#
# It will work with an boolean `success` value which is handed through the
# functions to define if everything went correct or something was not possible.
# If an real and unexpected error occur it will be thrown. All errors which
# aren't caught will end in an error and abort with exit code 2.
#
# ### Task libraries
#
# Each task is made available as separate task module with the `run` method
# to be called for each alinex package. The given command on the command line
# call may trigger multiple tasks which are done.
#
# Each task will get a `command` object which holds all the information from the
# command line call.


# Node Modules
# -------------------------------------------------

# include base modules
yargs = require 'yargs'
path = require 'path'
chalk = require 'chalk'
prompt = require 'prompt'
moment = require 'moment'
# include alinex modules
async = require 'alinex-async'
fs = require 'alinex-fs'
{string} = require 'alinex-util'
errorHandler = require 'alinex-error'
errorHandler.install()


# Configuration of shortcut groups
# -------------------------------------------------
groups =
  a: 'allgemein'
  b: 'betrieb'
  e: 'entwicklung'
  t: 'ticket'
  j: 'jira'

# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage("""
  Utility to log work times on different projects.

  Usage: $0 [task] [comment]
  .      $0 -r <report name> -d <date>
  """)
# examples
.example('$0 t-1212', 'to log the start on working on ticket 1212')
.example('$0', 'to end working on the previous task')
.example('$0 -r summary -d 2015-03', 'to get a summary report for the given date')
# report options
.string('r')
.alias('r', 'report')
.describe('r', 'show summary report in given format')
.alias('d', 'date')
.describe('d', 'select date for list or report using yyyy, yyyy-mm or yyyy-mm-dd')
# general help
.help('h')
.alias('h', 'help')
.showHelpOnFail(false, "Specify --help for available options")
.strict()
.argv


# Helper
# -------------------------------------------------
addlog = (task, desc, cb = ->) ->
  # extend task
  if task
    cat = task.split /-/
    task = groups[cat[0]] ? cat[0]
    task += '-' + cat[1..].join '-' if cat.length > 1
  # get logfile
  time = moment()
  dir = path.join __dirname, '../var/local/data'
  file = path.join dir, "#{time.format 'YYYY-MM'}.log"
  # output last log
  lastlog time, dir, file, ->
    # write new log
    fs.mkdirs dir, (err) ->
      return cb err if err
      msg = if task then "#{time.format()} #{task} #{desc}\n" else "#{time.format()}\n"
      fs.appendFile file, msg, (err) ->
        return cb err if err
        if task
          console.log "Your new task was logged."
        else
          console.log "Logged a stop of last task."
        cb()

lastlog = (time, dir, file, cb) ->
  fs.readFile file, 'utf-8', (err, text) ->
    return cb() if err
    lines = text.trim().split /\n/
    values = lines[lines.length-1].split /\ /
    # only go on if no end log
    return cb() unless values.length > 2
    stime = moment values[0]
    diff = Math.ceil time.diff stime, 'minutes', true
    task = values[1]
    desc = values[2..].join ' '
    console.log chalk.yellow "You worked on #{task} for #{diff} minutes (#{desc})."
    cb()

description = (argv, cb) ->
  if argv.length > 1
    return cb null, argv[1..].join ' '
  # ask for details
  prompt.start()
  prompt.get
    properties:
      detail:
        message: "Give some description to log #{task}"
        validator: /.{5,}/,
  , (err, input) ->
    return cb err, input?.detail

readlog = (date, cb) ->
  date ?= moment().format 'YYYY-MM-DD'
  dir = path.join __dirname, '../var/local/data'
  log = []
  # read all logs
  if date.length is 10
    file = path.join dir,  "#{date[0..6]}.log"
    fs.readFile file, 'utf-8', (err, text) ->
      return cb err if err
      for line in text.trim().split /\n/
        values = line.split /\ /
        if string.starts values[0], date
          names = values[1]?.split /-/
          log.push
            time: values[0]
            name: values[1]
            group: [names?[0], names?[1..].join '-']
            desc: values[2..]?.join ' '
      cb null, log
  else if date.length is 7
    file = path.join dir,  "#{date}.log"
    fs.readFile file, 'utf-8', (err, text) ->
      return cb err if err
      for line in text.trim().split /\n/
        values = line.split /\ /
        names = values[1]?.split /-/
        log.push
          time: values[0]
          name: values[1]
          group: [names?[0], names?[1..].join '-']
          desc: values[2..]?.join ' '
      cb null, log
  else
    async.each [1..12], (month, cb) ->
      file = path.join dir,  "#{date}-#{string.lpad month, 2, '0'}.log"
      fs.readFile file, 'utf-8', (err, text) ->
        unless err
          for line in text.trim().split /\n/
            values = line.split /\ /
            names = values[1]?.split /-/
            log.push
              time: values[0]
              name: values[1]
              group: [names?[0], names?[1..].join '-']
              desc: values[2..]?.join ' '
        cb()
    , (err) -> cb err, log

group = (logs) ->
  data = {}
  for log in logs
    # calculate previous line
    if last
      diff = Math.ceil moment(log.time).diff last.time, 'minutes', true
      day = last.time[0..9]
      data[day] ?= {}
      data[day][last.group[0]] ?= {}
      data[day][last.group[0]][last.group[1] ? '-'] ?=
        time: 0
        comment: []
      entry = data[day][last.group[0]][last.group[1]]
      entry.time += diff
      entry.comment.push last.desc unless last.desc in entry.comment
    # keep for next line
    last = if log.name? then log else null
  data

# Different reports
# -------------------------------------------------
report =
  # ### list
  # Chronological list of tasks which were done
  list: (logs, cb) ->
    console.log 'DATE\tSTART\tEND\tMINUTES\tGROUP\tTASK\tCOMMENT'
    last = null
    for log in logs
      # calculate previous line
      if last
        diff = Math.ceil moment(log.time).diff last.time, 'minutes', true
        console.log "#{last.time[0..9]}\t#{last.time[11..15]}\t#{log.time[11..15]}\t\
        #{diff}\t#{last.group[0]}\t#{last.group[1]}\t#{last.desc}"
      # keep for next line
      last = if log.name? then log else null
    cb()
  # ### summary
  # calculation of each task per day
  summary: (logs, cb) ->
    console.log "DAY\tMINUTES\tGROUP\tTASK"
    for day,data of group logs
      for category of data
        for task,entry of data[category]
          console.log "#{day}\t#{entry.time}\t#{category}\t#{task}"
    cb()

# Start the processing
# -------------------------------------------------
if argv.report?
  readlog argv.date, (err, logs) ->
    throw err if err
    unless report[argv.report]?
      console.error chalk.red "Please specify a valid report format: #{Object.keys(report).join ', '}"
    report[argv.report] logs, (err) ->
      throw err if err
else unless argv._?[0]
  addlog()
else
  task = argv._[0]
  description argv._, (err, desc) ->
    throw err if err
    addlog task, desc, (err) ->
      throw err if err
