# [177. Nth Highest Salary](https://leetcode.com/problems/nth-highest-salary/)(Create Function)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/110888763-34a79980-8330-11eb-9577-c8b7ecfecf67.png)

## \<Solving\>
**Points!**
1. 176번 문제와 같은 흐름이므로, 동일하게 Limit을 사용할 수 있다. 
2. 사용자 정의 함수를 통해 N을 입력하면 N번째 값이 나오게 한다. 
3. Limit은 N번째 이후의 값을 가져오므로, offset에는 N-1이 들어가야한다.  

### 1. Wrong Answer
```sql
CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
  RETURN (
      # Write your MySQL query statement below.
      select (
      select distinct Salary
      from Employee
      order by 1 desc
      limit N-1,1)
  );
END
```
```
Runtime Error

You have an error in your SQL syntax; 
check the manual that corresponds to your MySQL server version for the right syntax to use near '-1,1
  );
END' at line 8
```
#### 오답노트
1. `LIMIT`은 정수형 인자만 받을 수 있기때문에 수식`N-1`은 Offset 값으로 적절하지 않다.
>The `LIMIT` clause is used in the SELECT statement to constrain the number of rows to return.  
The `LIMIT` clause accepts one or two arguments.  
The values of both arguments must be **`zero`** or **`positive integers.`** 
 
2. 176번 문제에서 Ifnull 대신에 subquery를 사용하여 `Null`이 반환되게 했는데, 그 이유는 조회결과 값이 없으면 아무 값도 안나타 나지만,  
Null을 조회하면 `Null`이 반환되기 때문이었다. 이번 문제는 사용자함수 안에 select절을 사용하기 때문에,  
굳이 한번 더 함수 내에 subquery를 쓰지 않아도 된다. (틀린 것은 아니지만, 불필요함)
   
### 2. Final Submission
`SET N = N-1`으로 설정하여, Offset에 정수형태의 N-1값이 들어가게 수정한다.
```sql
CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
  SET N = N-1; 
  RETURN (select distinct Salary 
                from Employee 
                order by 1 desc
                limit N, 1);

END
 ```
 
![image](https://user-images.githubusercontent.com/74705142/110891138-bc8fa280-8334-11eb-8193-11cc2b1e2fd0.png)



