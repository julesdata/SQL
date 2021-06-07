# [183. Customers Who Never Order](https://leetcode.com/problems/customers-who-never-order/)

## \<Problem\>
![image](https://user-images.githubusercontent.com/74705142/120964332-25ed4900-c79e-11eb-9ff7-f3c7c5dc60dc.png)

## \<Solving\>
**Points!**: 
1.  Custoemrs와 Orders를 Left join하여, Orders가 Null인 고객 조회
2.  Foreign Key 주의 (Customers.ID = Orders.CustomerID)


### My Submission
```sql
select Customers.Name as Customers
from Customers left join Orders
On Customers.Id=Orders.CustomerId
where Orders.Id is Null 
```
```
{"headers": ["Customers"], "values": [["Henry"], ["Max"]]}
```
![image](https://user-images.githubusercontent.com/74705142/120964891-00ad0a80-c79f-11eb-9f4a-8bf69e2ab1b0.png)

## \<Other's Solutions\>

### 1. NOT IN
```sql
select name as Customers
from customers
where Id not in
(
    select CustomerId from orders
);
```
**Points!**: Orders table에서 ID가 없는 고객 조회  
