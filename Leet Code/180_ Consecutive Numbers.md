# [180. Consecutive Numbers](https://leetcode.com/problems/consecutive-numbers/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/111570896-1850a480-87e9-11eb-8400-a18f8ad3318d.png)

## \<Solving\>
**Points!**: 
1.  풀이 계획
2.  풀이 계획

### 1. Wrong Answer 1
```sql
query
```
```
result
```

#### 오답노트
내용

### 2. Wrong Answer 2
```sql
query
```
```
result
```

#### 오답노트
내용
    
### 3. Final Submission
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
