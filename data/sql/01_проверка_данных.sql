-- ============================================================
-- АО «Волковгеология» — Проверка качества данных
-- Аналитик: Нурбол Султанов
-- Дата: 2020-04-07
-- Описание: Валидация данных перед анализом OPEX
-- ============================================================

-- 1. Количество записей
SELECT 'drilling_operations' AS таблица, COUNT(*) AS кол_во FROM drilling_operations
UNION ALL
SELECT 'deposits', COUNT(*) FROM deposits
UNION ALL
SELECT 'cost_categories', COUNT(*) FROM cost_categories;

-- 2. Диапазон дат
SELECT 
    MIN(дата_начала) AS первая_дата,
    MAX(дата_начала) AS последняя_дата,
    COUNT(DISTINCT год) AS лет_в_данных
FROM drilling_operations;

-- 3. Проверка на NULL
SELECT 
    COUNT(*) AS всего,
    SUM(CASE WHEN номер_операции IS NULL THEN 1 ELSE 0 END) AS null_номер,
    SUM(CASE WHEN код_месторождения IS NULL THEN 1 ELSE 0 END) AS null_месторождение,
    SUM(CASE WHEN факт_тыс_тнг IS NULL THEN 1 ELSE 0 END) AS null_факт,
    SUM(CASE WHEN факт_тыс_тнг <= 0 THEN 1 ELSE 0 END) AS отрицательные_суммы
FROM drilling_operations;

-- 4. Подозрительные записи — тестовые данные
SELECT 
    код_месторождения,
    наименование_месторождения,
    COUNT(*) AS записей,
    SUM(факт_тыс_тнг) AS сумма_тыс_тнг
FROM drilling_operations
WHERE код_месторождения = 'МСТ-000'
   OR наименование_месторождения LIKE '%ТЕСТ%'
GROUP BY код_месторождения, наименование_месторождения;

-- 5. Затраты по годам и кварталам
SELECT 
    год,
    квартал,
    COUNT(DISTINCT номер_скважины) AS скважин,
    ROUND(SUM(факт_тыс_тнг) / 1000, 1) AS факт_млн_тнг,
    ROUND(SUM(план_тыс_тнг) / 1000, 1) AS план_млн_тнг
FROM drilling_operations
WHERE код_месторождения != 'МСТ-000'
GROUP BY год, квартал
ORDER BY год, квартал;

-- 6. Затраты по месторождениям
SELECT 
    наименование_месторождения,
    COUNT(DISTINCT номер_скважины) AS всего_скважин,
    ROUND(SUM(факт_тыс_тнг) / 1000, 1) AS факт_млн_тнг,
    ROUND(AVG(факт_тыс_тнг), 1) AS средний_факт_тыс
FROM drilling_operations
WHERE код_месторождения != 'МСТ-000'
GROUP BY наименование_месторождения
ORDER BY факт_млн_тнг DESC;

-- 7. Аномалии: отклонение факт/план > 50%
SELECT 
    номер_операции,
    наименование_месторождения,
    код_статьи,
    план_тыс_тнг,
    факт_тыс_тнг,
    отклонение_тыс_тнг,
    ROUND((факт_тыс_тнг - план_тыс_тнг) / NULLIF(план_тыс_тнг, 0) * 100, 1) AS отклонение_пцт
FROM drilling_operations
WHERE ABS(факт_тыс_тнг - план_тыс_тнг) / NULLIF(план_тыс_тнг, 0) > 0.5
ORDER BY отклонение_пцт DESC
LIMIT 20;