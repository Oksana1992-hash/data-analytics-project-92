--TASK 5--
-----------------------------------------------------
-- TOP_10_TOTAL_INCOME --
SELECT
    --получаем имя, фамилию продавца
    --количество совершённых продаж
    --общая выручка от продаж
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
--соединяем таблицы по id-шкам
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
--групируем по имени продавца
GROUP BY e.first_name, e.last_name
--сортируем по убыванию выручки продавца
ORDER BY income DESC
LIMIT 10;

-- LOWEST_AVERAGE_INCOME --
WITH
-- сначала найдём общую стоимость средней сделки
average_income_all AS (
    SELECT FLOOR(AVG(p.price * s.quantity)) AS main_average_income
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
),

averages AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        --получаем среднюю выручку продавца за сделку
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales AS s
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p ON s.product_id = p.product_id
    GROUP BY e.first_name, e.last_name
)

-- теперь можем найти худших продавцов
SELECT
    averages.seller,
    averages.average_income
FROM average_income_all, averages
WHERE averages.average_income < average_income_all.main_average_income
-- сортируем по возрастанию средней выручки продавца
ORDER BY averages.average_income;

-- DAY_OF_THE_WEEK_INCOME --
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    --преобразовываем дату в название дня недели
    REPLACE(LOWER(TO_CHAR(s.sale_date::DATE, 'Day')), ' ', '') AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
--групируем по имени и дню недели
GROUP BY
    e.first_name,
    e.last_name,
    TO_CHAR(s.sale_date, 'Day'),
    --это специальная функция, которая делает так,
    --что бы день недели начинался с понедельника
    EXTRACT(ISODOW FROM s.sale_date)
--сортируем по дню недели и имени
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;


--TASK 6--
-------------------------------------------------------
-- AGE_GROUPS --
SELECT
    -- оператор CASE с условиями для присвоения группы
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
-- условия распределения возрастной группы
WHERE
    age BETWEEN 16 AND 25
    OR age BETWEEN 26 AND 40
    OR age > 40
GROUP BY age_category
ORDER BY age_category;

-- CUSTOMERS_BY_MONTH --
SELECT
    -- выделяем год и месяц,
    -- берём общее количество уникальных покупателей
    -- суммируем общую выручку
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
--и групируем всё это дело по месячной выручке
GROUP BY selling_month
ORDER BY selling_month;

-- SPECIAL_OFFER --
WITH rang AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        -- тут присваем номера строкам через оконную функцию, разбивая записи
        -- по "customer_id" и сортируем с самых первых дат
        ROW_NUMBER()
            OVER (PARTITION BY s.customer_id ORDER BY s.sale_date)
            AS rn
    FROM sales AS s
)

SELECT
    r.sale_date,
    c.first_name || ' ' || c.last_name AS customer,
    e.first_name || ' ' || e.last_name AS seller
FROM rang AS r
INNER JOIN products AS p ON r.product_id = p.product_id
INNER JOIN customers AS c ON r.customer_id = c.customer_id
INNER JOIN employees AS e ON r.sales_person_id = e.employee_id
-- описания главного условия: первая строка (т.е. первая покупка) с ценой 0
WHERE r.rn = 1 AND p.price = 0
ORDER BY c.customer_id;
