# [184. Department Highest Salary](https://leetcode.com/problems/department-highest-salary/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/138231945-3da321be-c9a5-4e83-b511-112cc2c0cbb3.png)
![image](https://user-images.githubusercontent.com/74705142/138232258-57de8f88-3604-4698-b271-b30f09aaca46.png)


## \<Solving\>
**Points!**: 
1.  employee 테이블과 department 테이블 조인
2.  부서별 salary Rank() OVER 함수로 순위 구하기 (급여가 같은 사람은 모두 조회되도록 해야하므로, group by 후 Max Salary 불가)
  
### My Submission
```sql
SELECT Department, Employee, Salary 
FROM(
        SELECT b.Name Department, a.Name Employee, a.Salary
            , rank() over(PARTITION BY departmentid ORDER BY salary desc) Salary_rank
        FROM Employee a, Department b
        WHERE a.DepartmentId = b.Id
    ) a1
WHERE Salary_rank = 1
```
```
{"headers": ["Department", "Employee", "Salary"], "values": [["IT", "Jim", 90000], ["IT", "Max", 90000], ["Sales", "Henry", 80000]]}
```
![image](https://user-images.githubusercontent.com/74705142/138234714-a11b6826-9217-4f66-b973-7766febf67c1.png)

## \<Other's Solutions\>

### 1. 내용
```sql
SELECT 
    d.name AS 'Department',
    e.name AS 'Employee',
    salary
FROM Employee AS e
INNER JOIN Department AS d
ON e.DepartmentId = d.ID
WHERE 
    (e.DepartmentId, salary) IN
    (
        SELECT DepartmentId, max(salary) 
        FROM employee 
        GROUP BY DepartmentId
    );
```
**Points!**: 부서별 최고 급여 금액을 구해서, 부서 및 급여가 해당 조건과 같은 사원을 검색한다. 
             IN절 안에 group by, max salary 넣으면 가능.
   
   
### 2. 내용
```sql
SELECT Department, Employee, Salary 
FROM(
        SELECT b.Name Department, a.Name Employee, a.Salary
            , max(salary) over(PARTITION BY departmentid) max_salary
        FROM Employee a, Department b
        WHERE a.DepartmentId = b.Id
    ) a1
WHERE salary=max_salary
```
**Points!**: max() over함수로 최고급여와, 급여가 같은 사원 검색도 가능
