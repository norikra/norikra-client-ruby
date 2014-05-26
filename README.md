# Norikra::Client (norikra-client)

This is the client library implementation for Norikra, and its handy CLI commands.

`Norikra` is CEP server, based on Esper. You can install `gem install norikra` on your JRuby.
For more information, see http://norikra.github.io .

Command `norikra-client` and module `Norikra::Client` are provided for both of CRuby and JRuby.

 * For CRuby: `gem install norikra-client`
 * For JRuby: `gem install norikra-client-jruby`

Both have a same API and same data representaions. You can use which you want.

## Commands

Command `norikra-client` have some subcommands.

    norikra-client -h
    Commands:
      norikra-client event CMD ...ARGS    # send/fetch events
      norikra-client query CMD ...ARGS    # manage queries
      norikra-client target CMD ...ARGS   # manage targets
      norikra-client field CMD ...ARGS  # manage table field/datatype definitions
      
      norikra-client help [COMMAND]       # Describe available commands or one specific command
    
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

## API

### Norikra::Client.new(host, port, options={})

Instanciate with server's hostname and port number.

    require 'norikra-client'
    client = Norikra::Client.new('norikra.server.local', 26571)

Timeout options are available:

    client = Norikra::Client.new(
        'norikra.server.local',
        26571,
        connect_timeout: 3, send_timeout: 1, receive_timeout: 3
    )

### Norikra::Client#targets

Returns list of hashes, which contains `name`(string) and `auto_fields`(true/false) of each targets.

    client.targets #=> [{'name' => "demo", 'auto_field' => false}, {'name' => "sample", 'auto_field' => true}]

### Norikra::Client#open(target_name, fields=nil, auto_field=true)

Create new target on norikra server, to put events and queries. Returns true or false (successfully created, or already exists).

    client.open('sample') #=> true

Without fields, the specified target will be opend as 'lazy' mode, and actually opend when first input event arrived. Default field set will be determined at that time.

With field definitions, `#open()` creates the target and actually opens it immediately.

    client.open('sample', {id:'integer', name:'string', age:'integer', email:'string'})

Fiels specified on `#open()` are configured as default field set.

`auto_field` means which fields in arrived events are automatically added on field list, or not. Default is true.
`auto_field: true` helps you to know What fields input event streams have. You can watch fields list on norikra, and write queries. But in cases your input streams have great many field name patterns, norikra returns long list of field names. That is not understandable. In these cases, you should specify `auto_field false`.

In spite of `auto_field false`, norikra server adds fields which are used in registered queries automatically.

### Norikra::Client#close

Close the specified target. Norikra server stops all queries with that target.

    client.close('sample')   #=> true

### Norikra::Client#modify(target_name, auto_field)

Modify the specified target configuration of auto_field.

    client.modify('sample', false)   #=> true

### Norikra::Client#queries

Returns a list of hashes which contains `name`, `group`, `expression` and `targets` of registered queries.

    client.queries #=> [{'name' => 'q1', 'group' => nil, 'expression' => 'select count(*) from sample ...', 'targets' => ['sample']}]

Attributes of query:
  * `name`: the name of query, that must be unique on norikra server
  * `group`: the group name of query to be used in `sweep` call to fetch all events of queries with same `group` name (nil: default)
  * `expression`: SQL expression
  * `targets`: list of targets, which are referred in this SQL (2 or more targets by JOINs and SubQueries)

### Norikra::Client#register(query_name, query_group, query_expression)

Add query to norikra server. Query will be started immediately if all required targets/fields exists. If not, query actually starts when events arrived with all required fields.

    client.register('q1', nil, 'select count(*) from sample.win:time_batch(1 min) where age >= 20')  #=> true

### Norikra::Client#deregister(query_name)

Stop and remove specified query immediately.

    client.deregister('q1')   #=> true

### Norikra::Client#fields(target)

Returns the list of fields definitions, which contains `name`(string), `type`(string) and `optional`(true/false).

    client.fields('sample') #=> [{'name' => 'id', 'type' => 'integer', 'optional' => false}, ...]

NOTE: Hashes and arrays are just returned as 'hash' and 'array'. Nested fields and these types are not returned to client.

### Norikra::Client#reserve(target, field_name, type)

Specify the type of field, which not arrived yet.

    client.reserve('sample', 'phone', 'string')  #=> true

This api is useful for fields, which has int data at a time, and has string data at the other time. Norikra determines fields' type at the first time with that field, and format input data by determined type.
If you want to parse as int for a field but that field's value may be either String or Integer, you should do `reserve()` to determine it as `int`.

### Norikra::Client#send(target, events)

Send list of input events into norikra server.

    client.send('sample', [record1, record2, record3])

Members of events should be hash instance, which has a field at least.
Field values must be able to be serialized with MessagePack. Safe with String, Integer, Float, true/false/nil, Hash and Array.

### Norikra::Client#event(query_name)

Fetch events of specified query's output. Returns a list of `[time, event]`.

    client.event('q1') #=> [ [1383297109,{"count(*)":50}], [1383297169,{"count(*)":37}], ... ]

The first value of returned pairs is the time of output event as unix time (seconds from epoch).
The second value is output record of query as Hash.

### Norikra::Client#sweep(query_group=nil)

Fetch all output events of queries of specified group. `query_group: nil` means default query group. Returns Hash instance like `'query_name' => [list of output (same as #event)]`

    client.sweep() #=> for default group
    client.sweep('my_secret_group')

## Versions

* v0.1.0:
 * First release for production

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * MIT License
