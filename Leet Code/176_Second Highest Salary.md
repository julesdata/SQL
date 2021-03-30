# [176. Second Highest Salary](https://leetcode.com/problems/second-highest-salary/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/110578860-fa5fc000-81a8-11eb-974c-6352acfd58bf.png)

## \<Solving\>
**Points!**:
1. Hightst Salary -> salary를 내림차순
2. Second Higtst -> `Limit 1,1`을 사용하여 1번째 이후로 1개 값을 가져오자.  

### 1. Wrong Answer 1
```sql
select Salary as SecondHighestSalary
from Employee 
order by Salary desc
limit 1,1
```
```
Input:{"headers": {"Employee": ["Id", "Salary"]}, "rows": {"Employee": [[1, 100]]}}   
Output: {"headers": ["SecondHighestSalary"], "values": [ ]}   
Expected: {"headers": ["SecondHighestSalary"], "values": [[null]]}
```

#### 오답노트
'If there is no second highest salary, then the query should return null'이라는 제약조건을 skip했다.  
데이터가 1개만 있을 경우 2번째 값은 존재 하지 않으므로 아무런 값이 조회되지 않는다. 'null'로 조회되게 하는 코드를 생략하여 틀림 

### 2. Wrong Answer 2
```sql
select ifnull(
        (select Salary 
         from Employee 
         order by 1 desc
           limit 1,1), 
       NULL) as SecondHighestSalary
```
```
Input: {"headers": {"Employee": ["Id", "Salary"]}, "rows": {"Employee": [[1, 100], [2, 100]]}}   
Output: {"headers": ["SecondHighestSalary"], "values": [[100]]}   
Expected: {"headers": ["SecondHighestSalary"], "values": [[null]]}   
```

#### 오답노트 
'내림차순 정렬 두번째 값'이 꼭 '두번째로 높은 값'을 의미하지는 않음을 간과했다.   
가장 높은 값이 여러개 있을 수 있으므로, 'distict'한 값을 조회해야 한다.  
    
### 3. Final Submission
```sql
select ifnull(
        (select distinct Salary 
          from Employee 
          order by 1 desc
            limit 1,1),
        NULL) as SecondHighestSalary 
 ```
![image](https://user-images.githubusercontent.com/74705142/110585377-07ce7780-81b4-11eb-955c-4a3d507075b4.png)

## \<Other Solutions\>

### 1. Using Scalar sub-query
```sql
SELECT
    (SELECT DISTINCT
            Salary
        FROM
            Employee
        ORDER BY Salary DESC
        LIMIT 1 OFFSET 1) AS SecondHighestSalary
;
```
**Points!**: 특정 값을 조회 했을 때, 조건에 맞는 값이 없을 경우 아무 값도 조회되지 않지만,  
`SELECT NUll` 할 경우, `NULL`이 조회된다. 스칼라 서브쿼리 안에서 조회 값이 없으면, 원문은 Select Null을 한 셈이 된다. 
   
   
### 2. Top 1%'s Answer (using *max* clause and sub-query in where statement)
```sql
SELECT MAX(Salary) AS SecondHighestSalary
FROM Employee
WHERE Salary < (SELECT MAX(Salary) FROM Employee)
```
**Points!**: 가장 큰 값 보다 작은 값 중에서 가장 큰 값을 조회하면 두번째로 큰 값이 나온다.   

## \<What I Learned\>  

### 1. LIMIT 

\- `limit n` 이란 형태로 n번째 값 까지만 조회 하는 기능으로 알았는데  
\- `limit m , n` 으로 쓰면 m번째 값 이후로 n개의 값을 조회 할 수 있다.   
    ex) `limit 10, 4` : 11번째부터 4개, 즉 11-14 번째 값을 조회한다.
```sql
SELECT 
    select_list
FROM
    table_name
LIMIT [offset,] row_count;
```
In this syntax:
* The offset specifies the offset of the first row to return. The offset of the first row is 0, not 1.
* The row_count specifies the maximum number of rows to return.
The following picture illustrates the LIMIT clause:
![image](https://user-images.githubusercontent.com/74705142/110581946-cb4c4d00-81ae-11eb-8be9-84be0dc00fef.png)

참고: https://www.mysqltutorial.org/mysql-limit.aspx  
  
  
### 2. IFNULL  

- Oracle의 `NVL`과 같다. 
- `IFNULL(A , B )` : A가 NULL일 경우 B를 반환한다. NULL이 아닐경우 그대로 A를 반환 


참고: https://www.mysqltutorial.org/mysql-ifnull/

### 3. IFNULL 함수보다 Sub-query의 성능이 더 좋았다.
case by case 일 수 있으니 원리에 대한 공부 필요 
