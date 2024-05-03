-- Tổng quát
select count(distinct uid) as 'Tổng số người mua',
count(uid) as 'Tổng số đơn hàng',
sum(gmv) as 'Tổng doanh thu',
(select count(td2.order_id)   from transaction_data td2 where rebate >0) as 'Số Voucher'
from transaction_data td 
 
-- Số người mua, số đơn hàng, doanh thu theo ngày
select txn_date as 'Ngày', count(distinct uid) as 'Tổng số người mua', count(order_id) as 'Tổng số đơn hàng',
sum(gmv) as 'Tổng doanh thu'
from transaction_data td 
group by 1

-- đơn hàng có giá trị bao nhiêu nhiều nhất
select gmv as 'Giá trị đơn hàng', count(uid) as 'Số đơn hàng', sum(gmv) as 'Tổng doanh thu', sum(rebate) as 'Tổng số tiền giảm thực tế', 
20000*count(uid) as 'Số tiền được giảm tối đa'
from transaction_data td  group by 1 order by 2 desc 

-- 3 người mua có gian lận

-- số tiền min, max, median, avg của người mua
with a as (
			select uid, sum(gmv) as total
			from transaction_data td
			group by 1),
	b as (select *, rank() over(order by total) as rn from a)
select  min(total) as Min, avg(total) as Average, 
(select total from b where rn = 2300 limit 1) as Mean, max(total) as Max
from b

-- số đơn hàng min, max, median, avg của người mua
with a as (
			select uid, count(order_id) as total
			from transaction_data td
			group by 1),
	b as (select *, row_number () over(order by total) as rn from a)
select  min(total) as Min, avg(total) as Average, 
(select total from b where rn = 2301 limit 1) as Mean, max(total) as Max
from b

-- Khoảng cách giữa các giao dịch của cùng 1 người mua
with a as (
			select t1.uid, t1.txn_time as start, t2.txn_time as end
			from transaction_data t1
			inner join transaction_data t2
			on t1.uid = t2.uid and t1.order_id <> t2.order_id), 
	b as (select * , timediff(start, end) as Period from a)
select min(period) as Min, AVG(period) as Average, max(period) as Max from b where period >=0 

-- Phân tích từng ng mua theo tổng số tiền, số đơn, khoảng cách
with a as (
			select t1.uid, t1.txn_time as start, t2.txn_time as end
			from transaction_data t1
			inner join transaction_data t2
			on t1.uid = t2.uid and t1.order_id <> t2.order_id), 
	b as (select * , timediff(start, end) as Period from a),
	c as (select uid, sum(gmv) as Total_GMV , count(order_id) as Total_orders from transaction_data td group by 1),
	d as (select uid, min(period) as Min_period from b where  period >=0 group by 1 )
select d.uid,d.Min_period, c.Total_GMV, c.Total_orders
from d left join c on d.uid = c.uid
order by 4 desc


-- Phát hiện những đơn hàng có số tiền được giảm lớn hơn 30% so với tổng giá trị đơn hàng
select uid, (case when gmv/70*30 > rebate then 'no' else 'yes' end) as 'cheat?'
from transaction_data td where  'cheat?' = 'yes'
=> Không có ai ...?

-- Phát hiện các uid có nhiều đơn có gmv nhỏ hơn 10000
select uid , count(gmv) as 'Số đơn hàng có giá trị nhỏ hơn 1k'
from transaction_data td  where gmv <1000 group by 1 order by 2 desc

-- Phát hiện những user seeding 100205391 
with a as (select uid, txn_time ,shop_id,gmv, rebate, row_number() over(order by txn_time) as rn
	from transaction_data td  where uid = 100205391),
 	b as (select a.uid, a.txn_time , t2.txn_time as Next_order, (timediff(a.txn_time,t2.txn_time)) as period, a.gmv, a.rebate, a.shop_id
	from a
	left join a t2
	on a.uid = t2.uid and a.rn < t2.rn 
	group by 1,2,3,5,6,7),
	c as (select *, ROW_NUMBER() OVER(PARTITION BY txn_time ORDER BY txn_time) as rn from b )
select * from c where rn = 1

-- Phát hiện những user seeding  100605978, 
with a as (select uid, txn_time ,gmv, rebate, row_number() over(order by txn_time) as rn
	from transaction_data td  where uid = 100605978),
 	b as (select a.uid, a.txn_time , t2.txn_time as Next_order, (timediff(a.txn_time,t2.txn_time)) as period, a.gmv, a.rebate
	from a
	left join a t2
	on a.uid = t2.uid and a.rn < t2.rn 
	group by 1,2,3,5,6),
	c as (select *, ROW_NUMBER() OVER(PARTITION BY txn_time ORDER BY txn_time) as rn from b )
select * from c where rn = 1

-- Phát hiện những user seeding  1026737
with a as (select uid, txn_time ,gmv, rebate, row_number() over(order by txn_time) as rn
	from transaction_data td  where uid = 1026737),
 	b as (select a.uid, a.txn_time , t2.txn_time as Next_order, (timediff(a.txn_time,t2.txn_time)) as period, a.gmv, a.rebate
	from a
	left join a t2
	on a.uid = t2.uid and a.rn < t2.rn 
	group by 1,2,3,5,6),
	c as (select *, ROW_NUMBER() OVER(PARTITION BY txn_time ORDER BY txn_time) as rn from b )
select * from c where rn = 1

-- Phát hiện uid dùng nhiều mã nhất
select uid, count(order_id) as 'Số lần dùng voucher' from transaction_data td where rebate = 20000 group by 1 order by 2 desc

select * from transaction_data td2 where shop_id  = 7181 order by 1


----- Người bán có khả năng gian lận

-- Tính giá trị đơn
with a as (
			select shop_id, sum(gmv) as Revenue , row_number() over(order by sum(gmv)) as rn from transaction_data td group by 1)
select min(Revenue) as Min, (select Revenue from a where rn = 693)as Median, avg(Revenue) as Average, max(Revenue) as Max
from a

-- số order 
with a as (
			select shop_id, count(order_id) as Total , row_number() over(order by count(order_id)) as rn from transaction_data td group by 1)
select min(Total) as Min, (select Total from a where rn = 693)as Median, avg(Total) as Average, max(Total) as Max
from a

-- số lượng khách mua 
with a as (
	select shop_id, count(distinct uid) as Total , row_number() over(order by count(distinct uid)) as rn from transaction_data td group by 1)
select min(Total) as Min, (select Total from a where rn = 693)as Median, avg(Total) as Average, max(Total) as Max
from a

-- các shop_id có sự bất thường
(select shop_id , sum(gmv) as 'Doanh thu' from transaction_data td group by 1 order by 2 desc),
(select shop_id, count(order_id) as 'Số đơn' from transaction_data td  group by 1 order by 2 desc),
(select shop_id , 
				count(distinct uid) as 'Số người mua' from transaction_data td  group by 1 order by 2 desc )

-- shop có số lượng đơn nhiều, số ng mua ít và giá trị đơn < 1k
with a as (select uid, shop_id, order_id,  gmv from transaction_data td where gmv < 1000 )
select shop_id, count(distinct uid) as 'Số người mua', count(order_id) as 'Số đơn <1k' from a group by 1 order by 3 desc
		
-- check transaction các shop kia

-- shop 30140
select * from transaction_data td where shop_id = 30140
		
-- shop 30148
select * from transaction_data td where shop_id = 30148

-- shop 30185
select * from transaction_data td where shop_id = 30185

-- shop tương tác với uid nào nhiều nhất
select shop_id, uid, count(order_id) as 'Số giao dịch' from transaction_data td group by 1,2 order by 3 desc limit 15

-- tìm hiểu các shop có số tương tác cao với 1 người dùng.
select * from transaction_data td 
where shop_id in (29905, 4574,5643) 



