-- Таблица "customers_count"
-- Запрос на подсчет общего количество покупателей из таблицы customers
select
	COUNT(*) as customers_count
from customers c;

-- Таблица "top_10_total_income"
-- Выбираем имя продавца, объединяя имя и фамилию
select
    concat(e.first_name, ' ', e.last_name) as seller, -- Полное имя продавца
    -- Подсчитываем количество сделок (операций) для каждого продавца
    COUNT(s.sales_id ) as operations,
    -- Вычисляем общий доход продаж для каждого продавца, округляя до целого числа
    ROUND(SUM(s.quantity * p.price), 0) as income
from sales s
-- Объединяем таблицы sales и employees по идентификатору сотрудника
join employees e on e.employee_id =  s.sales_person_id
-- Объединяем таблицы sales и products по идентификатору продукта
join products p on p.product_id = s.product_id
-- Группируем по идентификатору сотрудника и имени продавца
group by e.employee_id , seller
-- Сортируем по суммарной выручке в порядке убывания
order by income desc
-- Ограничиваем результат ТОП-10 продавцами
limit 10;

-- Таблица "lowest_average_income"
-- Создаем временную таблицу (CTE) seller_avg, в которой рассчитываем средний доход каждого продавца
with seller_avg as (
	select
        -- Объединяем имя и фамилию сотрудника для получения полного имени продавца
		concat(e.first_name, ' ', e.last_name) as seller, -- Полное имя продавца
        -- Вычисляем средний доход (сумма quantity * цена), округленный до целого
		ROUND(AVG(s.quantity * p.price), 0) as average_income
	from sales s
    -- Объединяем таблицы sales и employees по идентификатору продавца
	join employees e on e.employee_id = s.sales_person_id
    -- Объединяем tabelы sales и products по идентификатору продукта 
	join products p on p.product_id = s.product_id
    -- Группируем данные по идентификатору сотрудника, чтобы получить средний доход для каждого продавца
	group by e.employee_id
),
-- Создаем второй CTE для вычисления общего среднего по всем продавцам
overall_avg as (
    select AVG(average_income) AS total_avg -- Общее среднее значение дохода всех продавцов
    from seller_avg
)
-- Выбираем продавцов, у которых их средний доход меньше общего среднего
select
    seller,
    average_income
from seller_avg
where average_income < (select total_avg from overall_avg) -- Фильтр по условию ниже среднего
-- Сортируем по доходу по возрастанию, чтобы показать продавцов с самым низким доходом первыми
order by average_income asc;

-- Таблица "day_of_the_week_income"
-- Выбираем имя продавца, объединяя имя и фамилию
select 
concat(e.first_name, ' ', e.last_name) as seller, -- Полное имя продавца
-- Получаем день недели для каждой продажи в текстовой форме, убираем лишние пробелы
trim(to_char(s.sale_date, 'day')) as day_of_week, -- День недели (например, 'monday')
-- Вычисляем общий доход за все продажи, сделанные в этот день недели продавцом
ROUND(SUM(s.quantity * p.price), 0) as income -- Общий доход, округленный до целого
from sales s
-- Объединяем таблицу продаж с таблицей сотрудников по ID продавца
join employees e on s.sales_person_id = e.employee_id
-- Объединяем таблицу продаж с таблицей продуктов по ID продукта
join products p on p.product_id = s.product_id
-- Группируем данные по ID продавца и дню недели (чтобы получить сумму по каждому продавцу за каждый день)
group by e.employee_id, trim(to_char(s.sale_date, 'day'))
-- Упорядочиваем результаты по порядку дней недели и имени продавца
order by case trim(to_char(s.sale_date, 'day'))
        WHEN 'monday' THEN 1
        WHEN 'tuesday' THEN 2
        WHEN 'wednesday' THEN 3
        WHEN 'thursday' THEN 4
        WHEN 'friday' THEN 5
        WHEN 'saturday' THEN 6
        WHEN 'sunday' THEN 7
    END,    -- Порядок дней недели от понедельника до воскресенья
    seller; -- Затем по имени продавца в алфавитном порядке

-- Таблица "age_groups"
-- Первый блок: подсчет количества клиентов в возрастной группе 16-25
select
	'16-25' as age_category, -- Название возрастной категории
	count(*) as age_count    -- Количество клиентов в этой группе
from customers
where age between 16 and 25  -- Выбираем клиентов с возрастом от 16 до 25 включительно
union all  -- Объединяет результаты с следующими запросами, создавая одну таблицу

-- Второй блок: подсчет количества клиентов в возрастной группе 26-40
select
	'26-40' as age_category, -- Название возрастной категории
	count(*) as age_count    -- Количество клиентов в этой группе
from customers
where age between 26 and 40  -- Выбираем клиентов с возрастом от 26 до 40 включительно
union all   -- Объединяет результаты с очередным запросом

-- Третий блок: подсчет количества клиентов старше 40
select
	'40+' as age_category,  -- Название возрастной категории
	count(*) as age_count   -- Количество клиентов в этой группе
from customers
where age > 40; -- Выбираем клиентов старше 40 лет

-- Таблица "customers_by_month"
select
	to_char(s.sale_date, 'YYYY-MM') as selling_month, -- дата в формате ГОД-МЕСЯЦ
	count(distinct s.customer_id) as total_customers, -- уникальные покупатели за месяц
	ROUND(SUM(s.quantity * p.price), 0) as income     -- выручка за месяц
from sales s
join products p on p.product_id = s.product_id -- присоединяем таблицу товаров для получения цены
group by to_char(sale_date, 'YYYY-MM')         -- группировка по месяцу
order by selling_month; -- сортировка по дате в порядке возрастания

-- Таблица "special_offer"
-- Находим все покупки со стоимостью 0 (бесплатные), для каждого клиента
with first_purchase as (
	select
		concat(c.first_name, ' ', c.last_name) as customer, -- Имя клиента (фамилия + имя)
		c.customer_id,                                      -- ID клиента
		s.sale_date,                                        -- Дата продажи
		p.price,                                            -- Цена товара (должна быть 0)
		s.sales_person_id,                                  -- ID продавца (сотрудника), реализовавшего продажу
        -- Номер строки для каждого клиента, сортировка по дате продажи (чтобы определить первую)
    	ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY s.sale_date) AS rn
	from customers c
	join sales s on c.customer_id = s.customer_id
	join products p on s.product_id = p.product_id
	where p.price = 0   -- Только бесплатные продажи
),
first_action_purchase as (
    -- Выбираем первую покупку (самую раннюю) для каждого клиента
	select
		customer,
		customer_id,
		sale_date,
		sales_person_id
	from first_purchase
    -- Только первая покупка по дате
	where rn = 1
),
-- Проверяем, что это действительно первая покупка: у клиента не было более ранних продаж
first_purchase_valid as (
    select
    	fp.customer,
    	fp.customer_id,
    	fp.sale_date,
    	fp.sales_person_id
    from first_action_purchase fp
    where not exists (
        -- Ищем более ранние продажи для этого клиента
        select 1
        from sales s2
        where s2.customer_id  = fp.customer_id
          and s2.sale_date < fp.sale_date
    )
)
-- Основной запрос: для каждой первой покупки ищем имя продавца
select
    fp.customer,                                        -- Имя клиента
    fp.sale_date,                                       -- Дата первой покупки
    concat(e.first_name, ' ', e.last_name) as seller    -- Имя продавца
from first_purchase_valid fp
join employees e on fp.sales_person_id = e.employee_id  -- Соединение по ID продавца
order by fp.customer_id;                                   -- Сортировка по имени клиента
