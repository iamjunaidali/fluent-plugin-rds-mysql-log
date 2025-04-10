# fluent-plugin-rds-mysql-log

## Overview
### AWS RDS log input plugin of Mysql for fluentd

This gem is customized specifically for **MySQL audit logs**, especially tailored for environments where **log rotation** is enabled. In such setups, audit logs rotate every 60 seconds, producing files with a numbered suffix like:

```
audit/server_audit.log.01 
audit/server_audit.log.02 
...
```

In my use case, I am using the [MariaDB Audit Plugin for MySQL](https://github.com/aws/audit-plugin-for-mysql) to generate these logs.

### Inspiration

This plugin is inspired by [fluent-plugin-rds-pgsql-log](https://github.com/shinsaka/fluent-plugin-rds-pgsql-log). 
I reused and adapted some of its ideas to handle MySQL audit logs more effectively.

### Handling Markers and Log Rotation

One of the key challenges with audit logs is **marker tracking**, because rotated log file names (like `server_audit.log.01`) are not timestamp-based and can repeat over time. This can cause Fluentd to:
- Read logs the first time with marker set to `0`
- Mark the file as "read" using the marker
- Then skip reading it again, even if new content arrives

To address this, there were two potential approaches:

A general behavior of master log file `audit/server_audit.log` is to receive logs continuously and rotated into `.01`, `.02`, etc., after reaching a size limit. 

#### ✅  Approach 1: Track markers for rotated files (e.g., `server_audit.log.01`, `.02`)

By always reading master file `audit/server_audit.log` from the beginning (`marker = 0`), we avoid duplicates and ensure complete log ingestion. While maintaining marker of rotated files avoid duplication.

#### ❌ Approach 2: Track markers for master file (`audit/server_audit.log`)

By always reading rotated files (e.g., `server_audit.log.01`, `.02`) from the beginning (`marker = 0`), we observed **duplicate log ingestion**.

**Therefore, adopting first approach** — treating the master audit log file as a fresh log source every time, while maintaining markers for rotated files.

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
