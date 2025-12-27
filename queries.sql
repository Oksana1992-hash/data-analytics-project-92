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
    END, -- Порядок дней недели от понедельника до воскресенья
    seller; -- Затем по имени продавца в алфавитном порядке
