# [184. Department Highest Salary](https://leetcode.com/problems/department-highest-salary/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/138231945-3da321be-c9a5-4e83-b511-112cc2c0cbb3.png)
![image](https://user-images.githubusercontent.com/74705142/138232258-57de8f88-3604-4698-b271-b30f09aaca46.png)


## \<Solving\>
**Points!**: 
1.  employee 테이블과 department 테이블 조인
2.  부서별 salary 순위 구하기 (급여가 같은 사람은 모두 조회되도록 해야하므로, group by 후 Max Salary 불가)
  
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
![image]

## \<Other's Solutions\>

### 1. 내용
```sql
query
```
**Points!**: 해설  
   
   
### 2. 내용
```sql
query
```
**Points!**: 해설 

## \<What I Learned\>  

### 1. 
내용
  
### 2.   
내용
