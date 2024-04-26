-- вывести работников по именам 
SELECT
    'employee' AS table_name,
    count(*) AS cnt
FROM
    hw.employee

UNION ALL
-- вывести тип работы
SELECT
    'work_type' AS table_name,
    count(*) AS cnt
FROM
    hw.work_type

UNION ALL
-- вывести тип рабочего часа
SELECT
    'work_hour_type' AS table_name,
    count(*) AS cnt
FROM
    hw.work_hour_type