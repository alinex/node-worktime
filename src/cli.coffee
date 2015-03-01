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
# include alinex modules
fs = require 'alinex-fs'
errorHandler = require 'alinex-error'
errorHandler.install()


# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage("""
  Utility to log work times on different projects.

  Usage: $0 task
  """)
# examples
.example('$0 t1212', 'to log the start on working on ticket 1212')
.example('$0', 'to end working on the previous task')
.example('$0 -l', 'to list the collected times')
# general options
.boolean('l')
.alias('l', 'list')
.describe('l', 'list log times')
.boolean('r')
.alias('r', 'report')
.describe('r', 'show summary report')
# push options
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
log = (task, desc, cb) ->
  time = (new Date).toISOString()[0..15].replace /T/, ' '
  dir = path.join __dirname, '../var/local/data'
  file = path.join dir, "#{time[0..6]}.log"
  fs.mkdirs dir, ->
    msg = if task then "#{time} #{task} #{desc}\n" else "#{time}\n"
    fs.appendFile file, msg, cb

# Run
# -------------------------------------------------
if argv.list
  console.log 'LIST'
else if argv.report
  console.log 'REPORT'
else unless argv._?[0]
  log()
else
  task = argv._[0]
  # ask for details
  console.log 'LOG'
  prompt.start()
  prompt.get
    properties:
      detail:
        message: "Give some description to log #{task}"
        validator: /.{5,}/,
  , (err, input) ->
    throw err if err
    log task, input.detail, (err) ->
      throw err if err
