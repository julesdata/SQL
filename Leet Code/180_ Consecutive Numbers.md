# [180. Consecutive Numbers](https://leetcode.com/problems/consecutive-numbers/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/111570896-1850a480-87e9-11eb-8400-a18f8ad3318d.png)

## \<Solving\>
**Points!**: 
1.  셀프조인을 통해 다음행, 다다음행의 결과를 붙여서 조회하기
2.  4회이상 연속적으로 나왔을 때, 중복값이 나올 수 있으니 distinct한 결과가 나오도록 할 것
    
### My Submission
```sql
select distinct A.num as ConsecutiveNums
from Logs A, Logs B, Logs C
where B.ID=A.ID-1
and C.ID=B.ID-1
and B.num=A.num
and C.num=B.num;
```
![image](https://user-images.githubusercontent.com/74705142/111571019-61085d80-87e9-11eb-9890-93bc929bda7b.png)

## \<Other Solutions\>

### 1. Group by
```sql
select l1.num ConsecutiveNums
from logs l1 left join logs l2 on l1.id = l2.id-1
left join logs l3 on l1.id = l3.id-2

where l1.num = l2.num
and l2.num = l3.num
group by l1.num
```
**Points!**: Group by 로 Distinct값 찾기  
   
   
### 2. LEAD OVER + Subquery 
```sql
WITH logs_lagged AS (
    SELECT
        Num
    , LEAD(NUM, 1) OVER(ORDER BY Id) AS NextNum
    , LEAD(NUM, 2) OVER(ORDER BY Id) AS ThirdNum
    FROM Logs
) 
SELECT DISTINCT Num AS ConsecutiveNums
    FROM logs_lagged
    WHERE Num = NextNum
        AND NextNum = ThirdNum
```
**Points!**:  
1. LEAD OVER로 다음행과 다다음행을 붙이기
2. With문 생성후 조회


## \<What I Learned\>

### LEAD OVER
The `LEAD()` function is a window function that allows you to look forward a number of rows and access data of that row from the current row.  
_`LEAD()` 함수는 현재 행 다음 N번째 오는 값을 동일한 행에서 보여준다. 비슷하게, `LAG()`함수는 현재 행 이전 N번째 값을 조회._
```sql
LEAD(<expression>[,offset[, default_value]]) OVER (
    PARTITION BY (expr)
    ORDER BY (expr)
)
```
* **expression**  
The `LEAD()` function returns the value of expression from the offset-th row of the ordered partition.  
_`LEAD()`함수는 그룹 안의 각 expression값에서 offset번째 행의 값을 반환한다._

* **offset**  
The `offset` is the number of rows forward from the current row from which to obtain the value.
The `offset` must be a non-negative integer. If `offset` is zero, then the `LEAD()` function evaluates the expression for the current row.
In case you omit `offset`, then the `LEAD()` function uses one by default.  
_`offset` 은 이후 몇번째 값을 반환할지 지정하는 숫자이며, 음수가 와서는 안된다. 0 입력시, 현재 값을 반환할거고, 생략 시에는 다음 1번째 행을 default로 반환한다._

* **default_value**  
If there is no subsequent row, the `LEAD()` function returns the `default_value`. For example, if `offset` is one, then the return value of the last row is the `default_value`.
In case you do not specify the `default_value`, the function returns `NULL` .  
_만약 다음 행이 없을 경우, 지정한  `default_value`값을 반환한다. 생략 시, `NULL`을 반환한다._

* **PARTITION BY clause**  
The `PARTITION BY` clause divides the rows in the result set into partitions to which the `LEAD()` function is applied.
If the `PARTITION BY` clause is not specified, all rows in the result set is treated as a single partition.  
_`PARTITION BY` 는 컬럼 내의 값 별로 그룹핑 및 분할하는 역할을 한다.  순서는 분할 기준에 해당하는 값들 내에서 매겨진다. 만약 `PARTITION BY`를 지정하지 않으면, 각 행을 하나의 파티션으로 취급한다._

* **ORDER BY clause**  
The `ORDER BY` clause determines the order of rows in partitions before the `LEAD()` function is applied. 
_`ORDER BY`는 파티션 내의 정렬을 어떻게 할것인지 기준을 세우며, 그 기준에 따라 LEAD()가 적용된다._
