# fluent-plugin-rds-mysql-log

## Overview
- Amazon Web Services RDS log input plugin for fluentd

This plugin has been created to deal with audit and error logs of mysql.

## Installation

    $ gem install fluent-plugin-rds-mysql-log

## AWS ELB Settings
- settings see: [Mysql Database Log Files](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.Mysql.html)

## When SSL certification error
log:
```
SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
```
Do env settings follows:
```
SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt (If you using amazon linux)
```

## Configuration

```config
<source>
  type rds_mysql_log
  # required
  region                 <region name>
  db_instance_identifier <instance identifier>
  # optional if you can IAM credentials
  access_key_id          <access_key>
  secret_access_key      <secret_access_key>
  # optional
  refresh_interval       <interval number by second(default: 30)>
  tag                    <tag name(default: rds-mysql.log>
  pos_file               <log getting position file(default: rds-mysql.log)>
</source>
```

### Example settings
```config
<source>
  type rds_mysql_log
  region eu-central-1
  db_instance_identifier test-mysql
  access_key_id     XXXXXXXXXXXXXXXXXXXX
  secret_access_key xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  refresh_interval  30
  tag mysql.log
  pos_file /tmp/mysql-log-pos.dat
</source>

<match mysql.log>
  type stdout
</match>
```

### json output example
```
Audit Logs:

{
  "time" => "20250403 19:41:01",
   "serverhost" => "ip-1-1-1-1",
   "host" => "1.2.3.4",
   "user" => "service",
   "database" => "test_db",
   "queryid" => "1234567890",
   "connectionid" => "12345678",
   "message" => "UPDATE table SET id=123, updated_at='2025-04-03 19:38:08.681797', is_weight_saved=1 WHERE table.id = 1234",
   "return_code" => "0",
   "log_file_name" => "server_audit.log"
}

Error Logs:

{
  "time" => "2025-03-21T00:00:04.275032Z",
   "thread_id" => "123456789",
   "severity" => "Warning",
   "error_code" => "MY-010055",
   "subsystem" => "Server",
   "message" => "IP address '1.2.3.4' could not be resolved: Name or service not known",
   "log_file_name" => "error.log"
}

```
