# [178. Rank Scores](https://leetcode.com/problems/rank-scores/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/110896061-2a8c9780-833e-11eb-8c51-2d37bd6d470c.png)

## \<Solving\>
**Points!**  
1. 랭크는 연속된 숫자로 표현되야함  -> `dense_rank` 사용 (`rank`와 구분)
2. 높은 점수로 내림차순 -> `order by Score desc`
3. 컬럼명(Rank)이 sql함수 이름과 같아서 오류가 나므로 ''를 사용하여 지정한다. -> `'Rank'`

### My Answer
```sql
select score, 
       dense_rank() over(order by Score desc
        ) 'Rank'
from Scores;
```

>Accepted  
>Runtime: 140 ms
```
Your input: {"headers": {"Scores": ["Id", "Score"]}, "rows": {"Scores": [[1, 3.50], [2, 3.65], [3, 4.00], [4, 3.85], [5, 4.00], [6, 3.65]]}}
Output:     {"headers": ["score", "Rank"], "values": [[4.00, 1], [4.00, 1], [3.85, 2], [3.65, 3], [3.65, 3], [3.50, 4]]}
Expected:   {"headers": ["Score", "Rank"], "values": [[4.00, 1], [4.00, 1], [3.85, 2], [3.65, 3], [3.65, 3], [3.50, 4]]}
```
![image](https://user-images.githubusercontent.com/74705142/110896539-2ad96280-833f-11eb-938b-726c25bdb593.png)

## \<What I Learned\>  

### 1. Rank
The `RANK()` function assigns a rank to each row within the partition of a result set.  
`RANK()`함수는 각 행의 순위를 부여한다. (속성별 순위 구분 가능)  
  
```sql
RANK() OVER (
    PARTITION BY <expression>[{,<expression>...}]
    ORDER BY <expression> [ASC|DESC], [{,<expression>...}]
)
```
* `PARTITION BY` clause divides the result sets into partitions.  
`PARTITION BY`를 통해 구분자를 정할 수 있다.  
The `RANK()` function is performed within partitions and re-initialized when crossing the partition boundary.  
속성이 구분될 때마다 순위는 그 안의 값 내에서 새롭게 매겨진다. 
* `ORDER BY` clause sorts the rows within a partition by one or more columns or expressions.  
 `ORDER BY`를 통해 어떤방향으로 순위를 매길지 선택한다. (오름차순|내림차순) 
Unlike `the ROW_NUMBER()` function, the `RANK()` function does not always return consecutive integers.  
`the ROW_NUMBER()`함수와 다르게, 항상 연속된 값을 반환하지는 않는다. 중복순위 갯수만큼 건너뛴다.  
(ex: 100(1), 90(2),90(2), 85(4) )  

    ![image](https://user-images.githubusercontent.com/74705142/110901059-113c1900-8347-11eb-8b7e-dd8b79924c66.png)

참고: https://www.mysqltutorial.org/mysql-window-functions/mysql-rank-function/

### 2. Dense_Rank   
`Rank()`와 같은 기능을 하되, 순위 값 반환을 연속적으로 한다. 하위 순위는, 상위순위 +1  
(ex: 100(1), 90(2),90(2), 85(3) )  
```sql
SELECT
    sales_employee,
    fiscal_year,
    sale,
    DENSE_RANK() OVER (PARTITION BY
                     fiscal_year
                 ORDER BY
                     sale DESC
                ) sales_rank
FROM
    sales;
```

The output is as follows:  

![image](https://user-images.githubusercontent.com/74705142/110900958-e6ea5b80-8346-11eb-8c6d-bee3ad6e8bfb.png)

참고: https://www.mysqltutorial.org/mysql-window-functions/mysql-dense_rank-function/
