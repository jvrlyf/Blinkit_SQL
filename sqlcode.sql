create database blinkit;

--------------------   SALES  ----------------------------------
		-- 1. Total sales
select round((Sales),2) as TotSales from grocery;
		-- 2. 	Total sales by Fats 
					update grocery                            # Replacing LF with Low Fat
					set `Item Fat Content` = 'Low Fat'
					where `Item Fat Content` = 'LF';

					update grocery							# Replacing reg with Regular
					set `Item Fat Content` = 'Regular'
					where `Item Fat Content` = 'reg';

select	`Item Fat Content`, sum(Sales) TotSales from grocery
group by `Item Fat Content`;

			-- 3. Sales by Item Type 
with A AS
(
select `Item Type`, round(sum(Sales),0) as Tsales from grocery
group by 1
)
select *, dense_rank() over	(order by Tsales desc) as Ranking
from A; 
			
            -- 4 . Sales by Year for each outlet size 
select `Outlet Establishment Year` as OutletYear, `Outlet Size`, round(sum(Sales),0) Tsales from grocery
group by 1,2
order by 1 asc;

		-- 5. Calculate the Sales Growth Rate Year-over-Year for Blinkit
alter table grocery            # Renamed Column 
rename column `Outlet Establishment Year` to OutletYear;
select * from grocery;

with B as
(
with A as 
(
select OutletYear, round(sum(Sales),0) Tsales from grocery
group by 1
order by 1 
)
select OutletYear, Tsales, lag(Tsales) over (order by OutletYear) as Lsales from A
)
select *, round(((Tsales -Lsales)/Lsales)*100.0,2) Growth from B;

		-- 6. Identify Outlets with Sales less than 13%  (Under Performing)
   with B as 
   (
   with A as
   (
	select `Outlet Identifier`, round(sum(Sales),2) Tsales from grocery
    group by 1
    )
    select *, concat(round(Tsales/(select sum(Sales) from grocery)*100.0,1), '%') as SalesPcnt from A
    )
    select *, 
		case
			when SalesPcnt >= 13 then 'Decent Performing'
            else 'Under Performing' 
            end as Statuss
	from B; 

		-- 7. Calculate the Contribution of Each Item Type to Total Sales
with A as
(
select `Item Type`, round(sum(Sales),2) Tsales,  
concat(round(round(sum(Sales),2)/(SELECT sum(Sales) from grocery)*100.0 , 2), '%') as Contribution 
from grocery
group by 1
)
Select *, dense_rank() over(order by Tsales desc) Ranking from A;


--------------------   RATINGS  ----------------------------------
-- a.	Calculate Avg ratings for each Item Type
select `Item Type` , 
round(avg(Rating),2) Ratings, dense_rank() over (order by round(avg(Rating),2) desc) Rankings 
from grocery
group by 1;

-- b. List the outlets with the highest average rating
select `Outlet Identifier`, round(avg(Rating),3) Ratings from grocery
group by 1
order by 2 desc;

-- c. Find the lowest rated item in each outlet (Bottom 3 items)
with B as 
(
With A as 
(
select `Outlet Identifier`, `Item Type`,avg(Rating) as Ratingss from grocery
group by 1,2
order by 1,3
)
select *, dense_rank() over (partition by `Outlet Identifier` order by Ratingss) Rankings from A
)
select * from B 
where Rankings < 4;

-- >>>>>>>> Create a view to see the average rating for each item type <<<<<<

select `Item Type`, avg(Rating) as Ratingss from grocery    --  COPY THIS SYNTAX IN VIEWS -- 
group by 1
;
	   -- VIEWS --					
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `ratingbyitem` AS
    SELECT 
        `grocery`.`Item Type` AS `Item Type`,
        AVG(`grocery`.`Rating`) AS `Ratingss`
    FROM
        `grocery`
    GROUP BY `grocery`.`Item Type`
    ;
    
    -- >>>>>> STORED PROCEDURE <<<<<< --
    
select `Item Type`, avg(Rating) as Ratingss from grocery
where `Item Type` = Enter_item
group by 1;

call ratings('Canned');


-- Create a stored procedure to get the highest rated item in a specific outlet
with A as 
(
select `Outlet Identifier`, 
`Item Type`, 
avg(Rating) as Ratingss, 
dense_rank() over (partition by `Outlet Identifier` order by avg(Rating) desc) as Rankings
from grocery
group by 1,2 
)
select * from  A
where `Outlet Identifier` = OI and Rankings = RK;

call highestratingBYstore('OUT017', 1);