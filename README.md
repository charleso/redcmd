Red creates (Redmine)[http://www.redmine.org/] issues from the command line.
============================================================================

0.1 (c) 2009 Dave Nolan textgoeshere.org.uk, github.com/textgoeshere/redcmd

Released under MIT license
==========================

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Example
=======

    red -s "Twitter integration FTW!!" -t feature -p cashprinter -r high -a "Some poor sod"
    # => "Created Feature #999 Twitter integration FTW!!!"

Command line arguments override settings in the configuration file, which override Redmine form defaults.

An example configuration file
=============================

    username: dave
    password: d4ve
    url: http://www.myredmineinstance.com
    project: redcmd
    tracker: bug
    priorty: normal   

I recommend creating a configuration file per-project, and sticking it in your path.

TODO
====

* due, start, done, est. hours
* custom fields
* subcommands (list, update, etc.)
