
/* ***

tst_as3.sql: try detecting extra io and extra SQL done for assersions..

pre-requirement: 
 - make sure to have EMP/DEPT from demobld  
 - run tst_ass.sql to create d_fnd, a_fnd, assertion and some data.
 - set up a tnsnames service tstass to allow fresh connections (too many containers.. )

examples of audit_definitions:
 - ...see original, and put more here if ...

setup is then:
 - create a table with the records from a_fnd to re-insert.
 - insert from fresh session (fresh restart even...)

notes, etc..
 - first test with many ins/upd, with/out assersion.
 - split into two assertions, the names would provide more info, efficient ? Test.
    - would give better errors, and each individual ass would be more eff, but more calls ?

 - a select in an assertion could yield some information as to what/where caused error ? 

*** */

conn scott/tiger@tstass

spool tst_as3

-- only if we need to prove version
-- select * from v$version ; 

-- we save the fnd-data for re-insertion..
drop table a_save_data ;
create table if not exists a_save_data  as
select a_def_id, deptno, empno, n_result from a_fnd ;

host read -t 15 -p "now reset the sh-pool or restart, press enter.." abc

conn scott/tiger@tstass

-- prompt do a zero-measurement
@mystat 

host read -t 15 -p "show the stats from a fresh-connection, no work done yet. press enter.." abc

conn scott/tiger@tstass 

/* 
now insert more findings in the fnd-table..
we just assume another audit is done, and it finds the same data...
*/

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

host read -t 15 -p "now check the stats after inserting, notably gets..." abc

prompt dont commit, preserve original state.
prompt then drop the assersion and try again..
rollback ;


set echo on
drop assertion a1_fnd_at_wrong_level ;

connect scott/tiger@tstass 

/* 
now insert same findings, but without the Assertion.. 
*/

set echo on
insert into a_fnd ( a_def_id, deptno, empno, n_result ) select * from a_save_data ;
set echo off

@mystat

host read -t 15 -p "now check the stats after inserting, without Asserions..." abc

prompt dont commit, preserve original state for repeated testing
rollback ;

-- re-install the assertion

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
)
/

spool off

