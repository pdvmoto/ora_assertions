
/* ***

tst_as3a.sql: re-run test of tst_as3 several times, in different order

pre-requirement: 
 - make sure tst_ass.sql and tst_as3.sql worked fine

setup is now:
 - re-insert same data several times and compare stats

notes, etc..
 - first test without assertion, test 3x..
 - re-add assertion, test 3x
 - later: add 2x or 3x the data, maybe highlight the diff.
 - later: split into two assertions, the names would provide more info, efficient ? Test.
    - would give better errors, and each individual ass would be more eff, but more calls ?

*** */

conn scott/tiger@tstass

spool tst_as3a

set echo on
drop assertion a1_fnd_at_wrong_level ;

connect scott/tiger@tstass

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

prompt.
prompt 1st insert, expect overhead for parsing..
host read -t 15 -p "check the stats after inserting, WITHOUT Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITHOUT Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

prompt .
prompt 3rd insert, stats should be equal to 2nd attempt
host read -t 15 -p "3rd check of stats after inserting, WITHOUT Asserions..." abc

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
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

prompt First run after create-assertion, expect overhead for parsing
host read -t 15 -p "check the stats after inserting, WITH Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

host read -t 15 -p "2nd check of stats after inserting, WITH Asserions..." abc

rollback ;

conn scott/tiger@tstass 

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

host read -t 15 -p "3rd run, WITH Asserions, should be equal to 2nd..." abc

rollback ;

spool off

