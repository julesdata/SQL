# [182. Duplicate Emails](https://leetcode.com/problems/duplicate-emails/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/120961334-9db87500-c798-11eb-8988-a3bb85398037.png)

## \<Solving\>
**Points!**: 
1.  Email로 그룹바이 후 
2.  having절로 이메일 갯수가 2개 이상인 이메일을 조회 

### My Submission
```sql
select Email 
from Person
group by Email
having count(Email)>=2
```
```
{"headers": ["Email"], "values": [["a@b.com"]]}
```

![image](https://user-images.githubusercontent.com/74705142/120962142-1f5cd280-c79a-11eb-9a4e-b2559857bf9e.png)

## \<Other' Solutions\>

### 1. from절 subquery에서 group by사용 
```sql
select Email from (
select Email, count(email) as num
from Person group by Email) as stat where num > 1;
```
**Points!**: 그룹바이로 이메일당 갯수를 조회하는 from절 서브쿼리문을 만들어, where절로 조회

