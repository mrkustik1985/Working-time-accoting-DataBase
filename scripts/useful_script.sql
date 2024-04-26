-- Вывести количество часов отработанных в выходные:
SELECT e.work_type_id, SUM(wh.hours_worked) AS total_hours_worked
FROM hw.employee e
JOIN hw.work_hours wh ON e.employee_id = wh.employee_id
JOIN hw.date d ON wh.date = d.date
WHERE d.holiday = true
GROUP BY e.work_type_id;

-- Вывести список типов работы, для которых среднее количество отработанных часов в неделю превышает 30 часов
SELECT e.work_type_id, AVG(hours_worked) AS avg_weekly_hours
FROM hw.work_hours wh
JOIN hw.employee e ON wh.employee_id = e.employee_id
JOIN hw.work_type wt ON e.work_type_id = wt.work_type_id
GROUP BY e.work_type_id
HAVING AVG(hours_worked) > 30
ORDER BY avg_weekly_hours DESC;

-- Вывести годовой доход каждого работника в 2023
SELECT e.firstname, e.surname, SUM(wh.hours_worked) AS total_hours_worked
FROM hw.employee e
JOIN hw.work_hours wh ON e.employee_id = wh.employee_id
WHERE '2023-01-01' <= wh.date and  wh.date < '2024-01-01' 
GROUP BY e.firstname, e.surname;

-- Вывести среднее количество отработанных часов для сотрудника за день
SELECT firstname, surname, avg(total_hours_worked)
from (
	SELECT e.firstname as firstname, e.surname as surname, e.work_type_id, avg(wh.hours_worked) AS total_hours_worked
	FROM hw.employee e
	JOIN hw.work_hours wh ON e.employee_id = wh.employee_id
	GROUP BY e.work_type_id, firstname, surname
)
group by firstname, surname;

-- Вывести соотношение рабочих часов по дням недели
select distinct employee_id, d.weekday,
sum(hours_worked) over(partition by employee_id, d.weekday) as sum_by_day,
sum(hours_worked) over(partition by employee_id) as total_sum	
from hw.work_hours wh
inner join hw.date d
on wh.date = d.date
order by wh.employee_id, d.weekday;

-- Вывести соотношение рабочих и нерабочих часов 
select distinct employee_id, hour_type_id,
		sum(hours_worked) over(partition by employee_id, hour_type_id) as sum_by_hour_type, 
		sum(hours_worked) over(partition by employee_id) as total_sum
						
from hw.work_hours wh
order by wh.employee_id, hour_type_id;

-- Вывести список сотрудников по дате приема на работу(если два сотрудника совпало по времени у них один rank)
select firstname, surname, employment_dt, 
	rank() over(order by employment_dt) 
from hw.employee