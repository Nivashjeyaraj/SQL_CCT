-- solve below questions

-- 1- write a query to print top 5 cities with highest spends 
-- and their percentage contribution of total credit card spends 

WITH cte AS
(SELECT *,
DENSE_RANK()OVER(ORDER BY High_spend DESC)AS Rn
FROM(SELECT city,SUM(amount) AS High_spend
	FROM credit_table
	GROUP BY city
    ORDER BY high_spend DESC) AS A
LIMIT 5)

SELECT *,
High_spend/(SELECT SUM(amount) FROM credit_table) * 100 AS Percentage
FROM cte;

-- 2- write a query to print highest spend month for each year 
-- and amount spent in that month for each card type

WITH cte AS
(SELECT *,
DENSE_RANK()OVER(PARTITION BY card_type ORDER BY year, mon, Tot_amount DESC) AS Rn,
CONCAT(year,mon) as PK1
FROM(
	SELECT card_type, YEAR(transaction_date)AS year, MONTH(transaction_date)AS mon, SUM(amount) AS Tot_amount
	FROM credit_table
	GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date))AS A),
cte2 AS
(SELECT *,CONCAT(year,mon) AS PK2
FROM
	(SELECT *,
	DENSE_RANK()OVER(PARTITION BY year ORDER BY High_spend DESC) AS Rn
	FROM
		(SELECT Year, mon,SUM(Tot_amount) AS High_spend
		FROM cte
		GROUP BY Year,mon
		ORDER BY High_spend DESC)AS A) AS B
WHERE Rn = 1)
SELECT TAB1.Year, TAB1.mon, TAB1.High_Spend AS Tot_SPEND,TAB2.card_type,TAB2.Tot_amount AS card_type_Amount
FROM cte2 AS TAB1
INNER JOIN cte AS TAB2
ON TAB1.PK2 = TAB2.PK1;

-- 3- write a query to print the transaction details(all columns from the table) 
-- for each card type when
	-- it reaches a cumulative of 1000000 total spends
    -- (We should have 4 rows in the o/p one for each card type)
    
SELECT * FROM credit_table;
WITH cte AS
(SELECT *
FROM(
	SELECT *,
	SUM(amount)OVER(PARTITION BY card_type ORDER BY transaction_date,Transaction_id) AS Cumulative
	FROM credit_table) AS A
WHERE Cumulative > 1000000)
SELECT *
FROM(
	SELECT *,
	DENSE_RANK()OVER(PARTITION BY card_type ORDER BY Cumulative) AS Rn
	FROM cte) AS B
WHERE Rn = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type

WITH cte AS
(SELECT *
FROM(
	SELECT city,card_type,SUM(amount) AS tot
	FROM credit_table
	GROUP BY city,card_type) AS A
WHERE card_type LIKE "Gold")
SELECT City
FROM
	(SELECT *,DENSE_RANK()OVER(ORDER BY Percentage) AS Rn
	FROM(
		SELECT *, tot/(SELECT SUM(tot) FROM cte) * 100 AS Percentage
		FROM cte)AS A) AS B
WHERE Rn = 1;
    
-- 5- write a query to print 3 columns:  
-- city, highest_expense_type , lowest_expense_type 
-- (example format : Delhi , bills, Fuel)

WITH cte1 AS
(SELECT City,exp_type, SUM(Amount) AS tot
FROM credit_table
GROUP BY City,exp_type
ORDER BY city),
cte2 AS
(SELECT City,MAX(tot) AS max,MIN(tot) AS min
FROM cte1
GROUP BY City),
cte3 AS 
(SELECT A.*,B.max,B.min
FROM cte1 AS A
INNER JOIN cte2 AS B
ON A.city = B.city)

SELECT A.City,A.Exp_type AS Highest_expenses,B.Exp_type AS Lowest_expenses
FROM cte3 AS A
INNER JOIN (
			SELECT City,Exp_type 
			FROM cte3
            WHERE tot = Min) AS B
ON A.city = B.city            
WHERE tot = max;


-- 6- write a query to find percentage contribution of spends by females for each expense type

SELECT * FROM credit_table;

WITH cte AS 
(SELECT exp_type,gender, Sum(Amount) AS each_tot
FROM credit_table
GROUP BY Exp_type,gender
ORDER BY exp_type),
cte2 AS
(SELECT exp_type, SUM(each_tot) AS tot
FROM cte 
GROUP BY exp_type),
cte3 AS
(SELECT A.*,B.tot
FROM cte AS A
INNER JOIN cte2 AS B
ON A.exp_type = B.exp_type
WHERE gender LIKE "F")
SELECT exp_type, (each_tot/tot)*100 AS percentage
FROM cte3;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

SELECT * FROM credit_table;
WITH cte AS
(SELECT YEAR(transaction_date)AS Yr,MONTH(transaction_date)AS Mon, card_type,exp_type,SUM(AMOUNT) AS tot
FROM credit_table
GROUP BY YEAR(transaction_date),MONTH(transaction_date), card_type,exp_type),
cte2 AS 
(SELECT *,
LAG(tot)OVER(PARTITION BY card_type, exp_type ORDER BY Yr,Mon) AS prev
FROM cte )

SELECT *, (tot-prev) AS profit
FROM cte2
WHERE mon=1 AND yr=2014 AND prev IS NOT NULL
ORDER BY profit DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to 
-- total no of transcations ratio 
select * from credit_table;
WITH cte AS
(SELECT City ,SUM(amount) AS Total,COUNT(Transaction_id) AS tot_transaction
FROM credit_table
WHERE DAYNAME(transaction_date) IN ("Saturday","Sunday")
GROUP BY City
ORDER BY City)

SELECT City,total/tot_transaction AS Ratio
FROM cte
ORDER BY Ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after 
-- the first transaction in that city
WITH cte as(
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) as rn
	FROM credit_TABLE
)
SELECT city, TIMESTAMPDIFF(DAY, MIN(transaction_date), MAX(transaction_date)) as datediff
FROM cte
WHERE rn=1 or rn=500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY datediff
LIMIT 1;
