
/* ***

tst_as3b.sql: re-run test of tst_as3 with larger numbers

pre-requirement: 
 - make sure tst_ass.sql and tst_as3.sql worked fine

setup is now:
 - re-insert same data several times and compare stats

notes, etc..
 - first test without assertion, test n executes
 - re-add assertion, test another n executes

notes: use similar sql to find differences
select s.rows_processed, s.executions, s.buffer_gets, s.* from v$sql s 
where upper ( sql_text) like '%ORA$SA$%' 
and upper ( sql_text ) not like '%SQL_TEXT%'
order by first_load_time desc ; 

column rws_p_x format  999.9
column buf_p_x format 9999.9
column sqltxt format A35

select s.rows_processed / s.executions as rws_p_x
--, s.executions
--, s.buffer_gets
, s.buffer_gets / s.executions buf_p_x
, substr ( s.sql_text , 1, 32 ) sqltxt
--, s.* 
from v$sql s 
where lower ( sql_text) like '%tst_as3b%' 
and upper ( sql_text ) not like '%SQL_TEXT%'
order by first_load_time desc ; 
*** */

conn scott/tiger@tstass

spool tst_as3b

set echo on
drop assertion a1_fnd_at_wrong_level ;

prompt we save the fnd-data for re-insertion..
drop table a_save_data ;
create table if not exists a_save_data  as
select a_def_id, deptno, empno, n_result from a_fnd ;

prompt multiply the data too have some relevant numbers.
insert into a_save_data select * from a_save_data ; 

/
/
/
/

prompt now should have about 600 rows in the table, data to play with

-- clean out shpool
alter system flush shared_pool; 

connect scott/tiger@tstass

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
host read -t 15 -p "check the stats for overhead (1/3x) ..." abc

connect scott/tiger@tstass

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
host read -t 15 -p "check the stats for overhead (2/3x) ..." abc

connect scott/tiger@tstass

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
prompt on third attempt, numbers should be similar
host read -t 15 -p "check the stats for overhead (3/3x) ..." abc

connect scott/tiger@tstass

set echo on
insert /* tst_as3b without */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/ 
/
/
/

set echo off

@mystat

prompt.
prompt 1st insert, expect overhead for parsing..
host read -t 15 -p "check the stats after inserting, WITHOUT Asserions (1/3)..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert /* tst_as3b without */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/ 
/
/
/

set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITHOUT Asserions (2/3)..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert /* tst_as3b without */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/
/
/
/

set echo off

@mystat

prompt .
prompt 3rd insert, stats should be equal to 2nd attempt
host read -t 15 -p "3rd check of stats after inserting, WITHOUT Asserions (3/3)..." abc

rollback ;
prompt .
prompt re-install the assertion...
prompt .

set echo on

create assertion a1_fnd_at_wrong_level
check (
  not exists (
    select 'E_finding_at_D_level' as a1_result
      from a_def ad
         , a_fnd af
     where ad.id = af.a_def_id            -- join to a_def
       and (
              (   ad.a_lvl = 'DEPT'       -- invalid combination.
              and af.empno is not null    -- Dept level finding with Emp-key
              )
           OR (   ad.a_lvl = 'EMP'
              and af.deptno is not null   -- Emp level finding with a Dept-key
              )
           )
  )
) ;

set echo off

host read -t 15 -p "assertion re-created, now expect extra effort..." abc

connect scott/tiger@tstass

set echo on
insert /* tst_as3b with */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/
/
/
/

set echo off

@mystat

prompt First run after create-assertion, expect overhead for parsing
host read -t 15 -p "check the stats after inserting, WITH Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert /* tst_as3b with */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/
/
/
/

set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITH Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert /* tst_as3b with */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/
/
/
/

set echo off

@mystat

host read -t 15 -p "3rd run, WITH Asserions, should be equal to 2nd..." abc

rollback ;

column rws_p_x format  999.9
column buf_p_x format 9999.9
column cpu_p_x format 99999
column ela_p_x format 99999
column sqltxt format A35

select 
  s.rows_processed / s.executions as rws_p_x
--, s.executions
--, s.buffer_gets
, s.cpu_time / s.executions       cpu_p_x
, s.elapsed_time / s.executions   ela_p_x 
, s.buffer_gets / s.executions    buf_p_x
, substr ( s.sql_text , 1, 32 )   sqltxt
--, s.*
from v$sql s
where lower ( sql_text) like '%tst_as3b%'
and upper ( sql_text ) not like '%SQL_TEXT%'
order by first_load_time desc ;

spool off

