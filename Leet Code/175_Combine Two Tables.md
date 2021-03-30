## [175. Combine Two Tables](https://leetcode.com/problems/combine-two-tables/)
### \<Problem\>

![image](https://user-images.githubusercontent.com/74705142/110563205-4a7d5900-818e-11eb-980e-70ae673411b5.png)

### \<Solving\>
**Points!**
1. PersonId 컬럼이 Foreign키이다. 
2. address의 유무와 상관없이 가져오라고 했으므로, Person table을 기준으로 Left outer join한다. 

#### My Answer

```sql
select A.FirstName,A.LastName, B.City, B.State
from Person as A left join Address as B 
                    on A.PersonId = B.PersonId;
```
![image](https://user-images.githubusercontent.com/74705142/110563873-4867ca00-818f-11eb-901f-85dd0289003b.png)

#### Top 1%'s Code 
```sql
select FirstName, LastName, City, State
from Person left join Address
on Person.PersonId = Address.PersonId
;
```

**What I Learned** : 
컬럼명이 독립적일 경우, 컬럼명 앞에 테이블 별칭을 붙히지 않아도 된다. 
