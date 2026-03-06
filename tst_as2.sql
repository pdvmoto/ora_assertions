
-- tst_as2.sql: test a sum-total constraint. 
--
-- background: on large numbers this might be in-efficient on purpose.. ? 
--

-- every dept has a budget for salary..
ALTER table dept add  ( sal_budget number ) 

-- the current budget would be...
select sum ( sal ) + sum(nvl( comm, 0)) , deptno from emp group by deptno ; 

update dept d set d.sal_budget =
  ( select sum ( sal) + sum ( nvl ( comm, 0 ) ) from emp where deptno = d.deptno ) ; 

commit ;

-- now we create an assertion that Fixes the Budget-numbers.. hehehe
-- note: wonder if the select would be more efficient with an exist..
 
set echo on
create assertion ass_max_sal_budget 
check ( 
  ALL ( 
    select sum ( sal ) + sum(nvl( comm, 0)) as tot_sal
         , sal_budget
         , deptno 
    from emp e, dept d
    where e.deptno = d.deptno
    group by deptno
  ) salsum
  SATISFY (
    salsum.sal_budget >= salsum.tot_sal 
  )
);

set echo off

prompt .
prompt First Warning: no group by allowed here..
prompt So think of a more efficient SQL.. 
prompt .

-- better..

create assertion ass_max_sal_budget
check ( 
  not exists ( 
    select 'dept over budget'
    from dept d
    where 1=1
      and d.sal_budget > ( select sum ( sal ) + sum ( nvl ( comm, 0 ) ) from emp e
                          where e.deptno = d.deptno )
  )
);

prompt .
prompt second obstacle: no subquery allowed...
prompt .

-- try again.. how ?

