
prompt .
prompt and there is more..
prompt .

column rows_proc format 999999
column execs format 9999
column buf_g format 9999
column cpu_us format 999999
column ela_us format 999999

select s.rows_processed rows_proc
, s.executions execs
, s.buffer_gets buf_g
, s.cpu_time cpu_us
, s.elapsed_time ela_us
, substr ( s.sql_text , 1, 32 ) sqltxt
-- , s.*
from v$sql s
where upper ( sql_text) like '%ORA$SA$%'
and upper ( sql_text ) not like '%SQL_TEXT%'
order by sql_id, first_load_time desc
/


