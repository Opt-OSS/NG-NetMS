#Poll host
```bash
 ${NGNMS_HOME}/bin/AppRun.pl --mode=poll-host OPTIONS
 ```
#### OPTIONS:

| option|enviroment variable|defaul value|description|
|-------|-------------|-------|-------|
|--host| | **required** |Host in question IP or hostname
|--host-transport| | in-DB access record  | transport for host: SSHv1  SSHv2  Telnet
|--host-community| |in-DB access record  | SMNP community for host
|--host-user | |in-DB access record  |user name for login to host 
|--host-password| | in-DB access record |password for host
|--host-priveleged-password | |in-DB access record  |priveleged password for host
|--host-type| |DB access record  |host type : Supported hosts type
|-L --dbhost|NGNMS_DB_HOST|localhost|  Database host
|-D --dbname| NGNMS_DB| ngnms| database name
|-W --dbpassword|NGNMS_DB_PASSWORD| optoss| Database password
|-P --dbport|NGNMS_DB_PORT|5232| Database port
|-U --dbuser|NGNMS_DB_USER|ngnms|          Database user

#Audit
### with all params in database
```bash
${NGNMS_HOME}/bin/audit_run.sh
```
This script auto-created by `scheduler` process and runs audit with the in-database audit's settings. 
Check script exists before executing.

### with custom params

```bash
 ${NGNMS_HOME}/bin/audit.pl
```
#### options
```
Usage: audit.pl [switches] host user passwd enpasswd accesstype[Telnet/SSHv1/SSHv2]                                         
                                                                                                                            
    Switches:                                                                                                               
    -np       skip poll stage                                                                                               
    -s           run subnets scanner                                                                                        
    -t type   host type                                                                                                     
    -L        DB host (default:localhost)                                                                                   
    -D        DB name                                                                                                       
    -U        DB User                                                                                                       
    -W        Pasword for DB user                                                                                           
    -P        DB Port                                                                                                       
    --force-rediscovery Force new discovery. That is - even if previouse process still running,
                        it will be stopped and new process started   
    Example:                                                                                                                
    audit.pl c1600 "" cisco cisco Telnet                                                                                    
    audit.pl -s -L localhost -D ngnms -U ngnms -W ngnms 192.168.3.1 lab cisco cisco SSHv2                                   
    Environment:                                                                                                            
    NGNMS_DEBUG - if set to 1, equivalent to -d switch set. Use for debug.                                                  
```                                                                                             

# Job machine

job machine holds 2 tables in jobmachine schema

* table `class`: 
    - `name` queue name
    - `id` - queue ID
* table `task`: 
   - `task_id`: task_id, `class_id` - id of queue from `class` table
   - `parameters`: json string with parameters related to task
   - `status` - task status
   
task statuses:

|value| description|
|----|----|
|0| task is  awaiting execution
|100| task is executing
|200| task finished successfully
| &gt;200| task failed 

each queue name has 2 prefixes - `jm` for send and `jmr` for replay 'channels'

to add job, get or create if not exists class ID from `class` table by queue name,
insert task into table `task`, then send notify to workers via `jm:queue_name` channel

example:

table `class`

|id | name  |
|:----:|:------:|
|1 |'audit.runner'|

execute SQL:
```sql

INSERT INTO jobmachine.task
            (class_id,parameters,status)
        VALUES (1,'["start"]',0)
        RETURNING task_id;
        
SELECT PG_NOTIFY('jm:audit.runner',null);

``` 
this will start audit on machine where audit-worker is running
>  file `${NGNMS_HOME}/bin/audit_run.sh` will be executed on machine which first takes `audit.runner` task

   
###possible commands:

#### start audit

queue name: `audit.runner`

Parameters: 
 ```json
["start"]
 ```
> To prevent duplicate audits or sequential audit started: 
 control    `task.status` field for this queue name before submitting new task 

#### archive load

queue name: `archive.load`

Parameters: 
 ```json
{'archive_id':Archve_id} 
 ```
 > `Archive_id` - record id in  table `archives`
 
#### archive unload

queue name: `archive.unload`

Parameters: 
```json
{'archive_id':Archve_id} 
```
> `Archive_id` - record id in table `archives`  