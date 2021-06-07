# [181. Employees Earning More Than Their Managers](https://leetcode.com/problems/employees-earning-more-than-their-managers/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/120958081-e3257400-c791-11eb-8da8-d5bfc5850c3b.png)

## \<Solving\>
**Points!**: 
1. 셀프조인을 통해 매니저 샐러리를 함께 생성하고 
2. 매니저 샐러리보다 본인 샐러리가 높은 직원이름을 조회 

### My Submission
```sql
select A.Name as Employee
from Employee A, Employee B
where A.ManagerId = B.Id
and A.Salary > B.Salary

```
![image](https://user-images.githubusercontent.com/74705142/120959370-92634a80-c794-11eb-98a2-99e2e4de8d71.png)

## \<Other Solutions\>

### 1. where절 서브쿼리
```sql
select Name as Employee
from Employee E
where E.salary > (
                  select Salary 
                  from Employee M
                  where E.ManagerId = M.Id
                  )
```
**Points!**: where절에서 해당 매니저 아이디의 급여를 조회하는 subquery를 이용, 직원 급여와 비교 
