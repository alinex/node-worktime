Package: alinex-worktime
=================================================

[![Build Status] (https://travis-ci.org/alinex/node-worktime.svg?branch=master)](https://travis-ci.org/alinex/node-worktime)
[![Dependency Status] (https://gemnasium.com/alinex/node-worktime.png)](https://gemnasium.com/alinex/node-worktime)

This tool will help to log work-times for different tasks.


Install
-------------------------------------------------

Install the package globally using npm:

    > sudo npm install -g alinex-worktime --production

After global installation you may directly call `worktime` from anywhere.

    > worktime --help

[![NPM](https://nodei.co/npm/alinex-worktime.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-worktime/)


Usage
-------------------------------------------------

    Usage: `worktime [task] [comment]`
           `worktime -r <report-name> -d <date>`

    Options:
      -r, --report  show summary report in given format
      -d, --date    select date for list or report using yyyy, yyyy-mm or yyyy-mm-dd

      -h, --help    Show help


Examples:
-------------------------------------------------

    worktime t-1212                    to log the start on working on
                                             ticket 1212
  node bin/worktime                          to end working on the previous task

  node bin/worktime -r summary -d 2015-03    to get a summary report for the
                                             given date



License
-------------------------------------------------

Copyright 2015 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
