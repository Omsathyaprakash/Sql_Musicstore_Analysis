--Music Store Data Analysis Project

-- 1.who is the senior most employeee based on job title?
select * from employee
order by levels desc
limit 1

--2.which countries have the most invoices?
select billing_country,count(*) from invoice
group by billing_country
order by count(*) desc

--3.What are the top 3 values of the total invoice
select TOTAL from invoice
order by TOTAL desc
limit 3

-- Q4:Which city has the best customers?
--We would like to throw a promotional Music Festival in the city we made the most money.
--Write a query that returns one city that has the highest sum of invoice totals. 
--Return both the city name & sum of all invoice totals

select billing_city,sum(total) 
						  from invoice
						  group by billing_city
						  order by sum(total) desc
						  LIMIT 1;
--OR
--if i want the complete details
 SELECT *
FROM Invoice
WHERE billing_city = (
    SELECT Billing_City
    FROM Invoice
    GROUP BY Billing_City
    ORDER BY SUM(Total) DESC
	limit 1
	);
   
--Q5: Who is the best 5 customer?
--The customer who has spent the most money will be declared the best customer.
--Write a query that returns the person who has spent the most money.


select customer.customer_id,customer.first_name,customer.last_name ,sum(invoice.total) as total
from customer
join invoice on customer.customer_id=invoice.customer_id 	
group by customer.customer_id
order by total desc
limit 5

--i want Best 5 customers and their complete details ( we r using sub query here)
select * from customer
where customer_id in
(select customer.customer_id from customer
join invoice on customer.customer_id=invoice.customer_id 	
group by customer.customer_id
order by sum(invoice.total) desc
limit 5)


--LEVEL 2--MODERATE

--Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A

select Distinct email,first_name,last_name
from customer
join invoice on invoice.customer_id=customer.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
where track_id in(
SELECT TRACK_ID FROM TRACK
JOIN GENRE ON TRACK.GENRE_ID=GENRE.GENRE_ID
WHERE GENRE.NAME LIKE 'Rock')
order by email;

--Q2: Let's invite the artists who have written the most rock music in our dataset.
--Write a query that returns the Artist name and total track count of the top 10 rock bands

--optimized way
select artist.name,count(*)as Songs_composed from artist
join album on artist.artist_id=album.artist_id
join track on album.album_id=track.album_id
WHERE GENRE_ID=
(select genre_id from genre
where name='Rock')
group by artist.name
order by  Songs_composed desc
limit 10
--or
select DISTINCT email,first_name,last_name
from customer
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on invoice_line.track_id=track.track_id
join genre on genre.genre_id=track.genre_id
where genre.name='Rock'
order by email;

--Q3: Return all the track names that have a song length longer than the average song length.
--Return the Name and Milliseconds for each track.
--Order by the song length with the longest songs listed first.

select name,milliseconds
from track
where milliseconds>
(select avg(milliseconds) as avg_track_length from track)
order by milliseconds desc
--or
select name,milliseconds
from track
where milliseconds>393599
order by milliseconds desc

--LEVEL 3--ADVANCE

--Q1: Find how much amount spent by each customer on artists?
--Write a query to return customer name, artist name and total spent

WITH best_selling_artist AS (
SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
FROM invoice_line
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1 )
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


--Q2: We want to find out the most popular music Genre for each country.
--We determine the most popular genre as the genre with the highest amount of purchases.
--Write a query that returns each country along with the top Genre.
--For countries where the maximum number of purchases is shared return all Genres.

select * from 
(select billing_country,g.name as genre,count(il.quantity) noofpurchases,
rank() over (partition by billing_country
              order by count(il.quantity) desc) ranks
			  from invoice
join invoice_line il on invoice.invoice_id=il.invoice_id
JOIN track ON track.track_id = il.track_id
JOIN genre g on g.genre_id=track.genre_id
group by 1,2
order by 1 asc,3 desc)
where ranks=1

--USING RECURSIVE
WITH RECURSIVE
sales_per_country AS(
SELECT  customer. country, genre.name, genre. genre_id,COUNT (*) AS purchases_per_genre
FROM invoice_line
JOIN invoice ON invoice. invoice_id = invoice_line. invoice_id
JOIN customer ON customer. customer_id = invoice.customer_id
JOIN track ON track. track_id = invoice_line.track_id
JOIN genre ON genre. genre_id = track.genre_id
GROUP BY 1,2,3
ORDER BY 1
),
max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
FROM sales_per_country
GROUP BY 2
ORDER BY 2)
SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country. country = max_genre_per_country. country
WHERE sales_per_country. purchases_per_genre = max_genre_per_country.max_genre_number


--Q3: Write a query that determines the customer that has spent the most on music for each country.
--Write a query that returns the country along with the top customer and how much they spent.
--For countries where the top amount spent is shared, provide all customers who spent this amount
with cte as
(select customer.customer_id,customer.first_name,billing_country,sum(total) as totalspending,
row_number() over(partition by billing_country
                   order by sum(total) desc)
from invoice
join customer on invoice.customer_id=customer.customer_id
group by 1,2,3
order by 3)
select * from cte
where row_number=1

--USING RECURSIVE
WITH RECURSIVE 
customer_with_country as
(select customer.customer_id,customer.first_name,billing_country,sum(total) as totalspending from invoice
join customer on invoice.customer_id=customer.customer_id
group by 1,3
order by 1, 4 desc),
country_max_spending as (
select billing_country,max(totalspending) as maxspending
from customer_with_country
group by billing_country)
select cwc.billing_country,cwc.totalspending,cwc.first_name,cwc.customer_id
from customer_with_country cwc
join country_max_spending cms
on cwc.billing_country=cms.billing_country
where cwc.totalspending=cms.maxspending
order by 1










