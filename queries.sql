--Запрос на подсчет общего количество покупателей из таблицы customers
select
	COUNT(*) as customers_count
from customers c;