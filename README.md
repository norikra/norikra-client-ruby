# Norikra::Client (norikra-client)

This is the client library implementation for Norikra, and its handy CLI commands.

`Norikra` is CEP server, based on Esper. You can install `gem install norikra` on your JRuby.
For more information, see https://github.com/tagomoris/norikra .

Command `norikra-client` and module `Norikra::Client` are provided for both of CRuby and JRuby.

 * For CRuby: `gem install norikra-client`
 * For JRuby: `gem install norikra-client-jruby`

Both have a same API and same data representaions. You can use which you want.

## Commands

Command `norikra-client` have some subcommands.

    norikra-client -h
    Commands:
      norikra-client event CMD ...ARGS    # send/fetch events
      norikra-client help [COMMAND]       # Describe available commands or one specific command
      norikra-client query CMD ...ARGS    # manage queries
      norikra-client table CMD ...ARGS    # manage tables
      norikra-client typedef CMD ...ARGS  # manage table field/datatype definitions
    
    Options:
      [--host=HOST]
                     # Default: localhost
      [--port=N]
                     # Default: 26571

Of course, you can see helps of each subcommands by `norikra-client SUBCMD help`

## Client Library

In your programs, you can operate Norikra with Norikra::Client instances.

    require 'norikra-client'
    
    client = Norikra::Client.new     # connect to localhost:26571
    # client = Norikra::Client.new(hostname, portnum)

### Instance methods

TBD

## Versions

TBD

## TODO

* TBD

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * MIT License
