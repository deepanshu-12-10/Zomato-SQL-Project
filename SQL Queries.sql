Use Zomato;
select * from sales;
select * from users;
select * from goldusers_signup;
select * from product;
select distinct users.userid from users 
left join goldusers_signup on 
users.userid = goldusers_signup.userid;

/* 1. what is the Total amount Spent By Each Customer on Zomato ? */
select sales.userid ,sum(product.price) AS Total_amount_spent from sales 
left join product
on sales.product_id = product.product_id
group by sales.userid
order by sales.userid;

/* 2. How many days each customer visited to zomato ? */
select userid , count(distinct created_date) as days  from sales
group by userid;

/* 3. What was the first product purchased by the customer ?*/
with cte as (select s.userid as userid, s.product_id  as ProductID, p.product_name as ProductName, dense_rank() over(partition by userid order by created_date) as num 
from sales s
left join product p 
on s.product_id = p.product_id 
order by userid , created_date)
select distinct userid ,ProductID, ProductName from cte where num =1 ;

/* 4. What is the most purchased product from menu and how many times it was purchased by all customers */
with cte as (select p.product_name as ProductName , (count(*)) as times from sales s
left join product p
on s.product_id = p.product_id 
group by p.product_name)
select ProductName , times from cte 
order by times desc
limit 1;

/* 5.  which are the customers who pucharsed most selling product and how many times ?  */
select userid , count(*) as times  from sales 
where Product_id = 2
group by userid
order by times desc;

/* 6. which most favourite product of each customer and how many times they ordered it ? */
 select t.userid,t.product_id,p.product_name,t.Times, (t.times*p.price) as total_cost from (with cte as (select userid, product_id , count(product_id) as Times  from sales 
group by userid , product_id 
order by userid ) ,
cte2 as( select * , rank() over(partition by userid order by Times desc ) as rnk from cte)
select userid , product_id,Times from cte2
where rnk =1 ) t
left join product p 
on t.product_id = p.product_id;

/* 7. what first product was purchased by the customer after become the gold member of zomato ?*/
with cte as (select s.userid as UserID , s.created_date DatePurchase  ,s.product_id As ProductID ,g.gold_signup_date AS Gold_Member_SignUp_Date , rank() over (partition by s.userid order by s.created_date ) as rnk from sales s 
inner join goldusers_signup g
on s.userid = g.userid and s.created_date >= g.gold_signup_date
order by s.userid ,s.created_date)
select UserID , DatePurchase  ,ProductID ,Gold_Member_SignUp_Date  from cte where rnk =1  ;

/* 8. What product was purchased by the customer just before become the gold member of zomato? */
with cte as (select s.userid as UserID , s.created_date DatePurchase  ,s.product_id As ProductID ,g.gold_signup_date AS Gold_Member_SignUp_Date , rank() over (partition by s.userid order by s.created_date desc ) as rnk from sales s 
inner join goldusers_signup g
on s.userid = g.userid and s.created_date <= g.gold_signup_date
order by s.userid ,s.created_date)
select UserID , DatePurchase  ,ProductID ,Gold_Member_SignUp_Date  from cte where rnk =1 ;

/* 9. What is the total orders and total amount spent by each customer before they become gold member ? */
select a.userid, count(a.product_id) as total_orders ,sum(p.price) as total_amount from sales a 
inner  join goldusers_signup g
on a.userid = g.userid and a.created_date <= g.gold_signup_date 
left join product p 
on a.product_id = p.product_id
group by a.userid
order by a.userid ;

/* If buying each product generates points for example $5 = 2 zomato points and each product has different purchasing points like for p1 ,  $5 = 1point ,
 for p2  $10 = 5points and for p3 , $5 = 1 point .  ( for total money earnend by cashback points , 1 points = $2 ) ? */
with cte as (select s.userid as UserID, s.product_id as ProductID ,  count(s.product_id) as times   from sales s
group by s.userid, s.product_id
order by s.userid , s.product_id), 
 cte2 as (select UserID, ProductID, times , p.product_name ,(p.price*times) as total from cte left join product p 
on cte.ProductID = p.product_id),
cte3 as (select * , Case when ProductID =1 then (total /5 ) 
			    when ProductID =2 then (total /2)
                when ProductID = 3 then (total/5)
                end as Points 
                from cte2),
cte4 as ( select UserID, round(Sum(Points) ,1)  as total_points from cte3
                group by UserID) 
	select UserID, total_points , (total_points * 2) as total_earned_money  from cte4
		group by UserID;
        
        /* This question is like above question but in this we going to find out  
        total points genereated by each product and total money earned by each product .*/
with cte as (select s.userid as UserID, s.product_id as ProductID ,  count(s.product_id) as times   from sales s
group by s.userid, s.product_id
order by s.userid , s.product_id) ,
cte1 as ( select UserID, ProductID, times , p.product_name ,(p.price*times) as total from cte left join product p 
on cte.ProductID = p.product_id),
cte2 as (select ProductID , sum(total) as new_total from cte1 
group by ProductID),
cte3 as (select * , case when ProductID =1 then (new_total / 5 ) 
                  when ProductID =2 then (new_total / 2 ) 
                   when ProductID =3 then (new_total / 5 ) 
                   end as Total_points 
                   from cte2 )
                   select * , round(Total_points * 2) as total_money_generate_by_point_on_each_product from cte3 ;

      with cte as   (select s.userid,s.product_id, row_number() over(partition by s.userid order by s.product_id) as rnk from sales s 
        inner join goldusers_signup g
        on s.userid = g.userid and s.created_date >= g.gold_signup_date and s.created_date <= g.DATEADD(year,1,gold_signup_date)
        order by s.userid ),
     cte2 as    (select * from cte where rnk =1),
     cte3 as (select cte2.userid , cte2.product_id , p.product_name, p.price from cte2 left join product p 
     on cte2.product_id = p.product_id)
     select userid, round((price /2)) as points from cte3 ;
        