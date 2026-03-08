
/* ***

tst_as3b.sql: re-run test of tst_as3 with larger numbers

pre-requirement: 
 - make sure demobld.sql, tst_ass.sql and tst_as3.sql worked fine
 - prepare file connscott.sql to connect to schema e.g. "conn scott/tiger.." 

setup is now:
 - re-insert same data several times and compare stats

notes, etc..
 - save data to re-insert
 - first test without assertion, 
 -  run each test 3x on fresh session, and log sssion-stats
 - re-add assertion, test another n executes
 - check the insert-stmnts
 - check the additional stmnts on the funny tables

*** */

set pagesize 32
set heading on

@connscott

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

prompt now should have about 608 rows in the table, data to play with

-- clean out shpool
alter system flush shared_pool; 

@connscott

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
host read -t 15 -p "check the stats for overhead (1/3x) ..." abc

@connscott

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
host read -t 15 -p "check the stats for overhead (2/3x) ..." abc

@connscott

-- do nothing..
@mystat

prompt.
prompt measure overhead, session did nothing yet.. 
prompt on third attempt, numbers should be similar
host read -t 15 -p "check the stats for overhead (3/3x) ..." abc

@connscott

set echo on
insert /* as3b WITHOUT */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
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

@connscott

set echo on
insert /* as3b WITHOUT */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/ 
/
/
/

set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITHOUT Asserions (2/3)..." abc

rollback ;

@connscott

set echo on
insert /* as3b WITHOUT */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
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

@connscott

set echo on
insert /* as3b WITH   */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
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

@connscott

set echo on
insert /* as3b WITH   */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
select * from a_save_data ;

/
/
/
/

set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITH Asserions..." abc

rollback ;

@connscott

set echo on
insert /* as3b WITH   */ into a_fnd ( a_def_id, deptno, empno, n_result ) 
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
where       sql_text        like '%as3b W%'
and upper ( sql_text )  not like '%SQL_TEXT%'
order by first_load_time desc ;

spool off

