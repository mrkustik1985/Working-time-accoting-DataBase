
------------------------------------------------------------------------------------
--------------------------------------INDICES---------------------------------------
------------------------------------------------------------------------------------

CREATE INDEX ON hw.date (date);
CREATE INDEX ON hw.premium (employee_id, date);
CREATE INDEX ON hw.work_hours (employee_id, employee_valid_from, date);
CREATE INDEX ON hw.employee (employee_id);

------------------------------------------------------------------------------------
--------------------------------------VIEWS----------------------------------------
------------------------------------------------------------------------------------

-- Текущий штат фирмы
CREATE OR replace VIEW hw.current_staff_v AS
SELECT *
FROM hw.employee
WHERE valid_from <= current_date
  AND current_date < valid_to
ORDER BY firstname, surname;

-- Отработанные часы без лишней информации
CREATE OR replace VIEW hw.work_hours_v AS
SELECT employee_id, date, hours_worked, hour_type_id
FROM hw.work_hours;

-- Отработанные часы за последний год.
CREATE OR replace VIEW hw.year_paid_hours AS
SELECT e.employee_id, e.firstname, e.surname, sum(wh.hours_worked) AS total_hours
FROM hw.employee e
         LEFT JOIN hw.work_hours wh ON e.employee_id = wh.employee_id
         LEFT JOIN hw.work_hour_type wht ON wh.hour_type_id = wht.hour_type_id
WHERE wht.paid = true
  AND wh.date BETWEEN current_date - 365 AND current_date
GROUP BY e.employee_id, e.firstname, e.surname;

-- Ограниченная информация о сотрудниках.
CREATE OR replace VIEW hw.employee_info AS
SELECT employee_id, firstname, surname, hour_salary
FROM hw.current_staff_v
ORDER BY firstname, surname;

-- Выплаты за год.
CREATE OR replace VIEW hw.year_payments AS
SELECT e.employee_id, e.firstname, e.surname, p.payment + ph.total_hours * e.hour_salary AS payment
FROM hw.current_staff_v e
         LEFT JOIN hw.year_paid_hours ph
                   ON e.employee_id = ph.employee_id
         LEFT JOIN (SELECT employee_id, sum(payment) AS payment
                    FROM hw.premium
                    WHERE date BETWEEN current_date - 365 AND current_date
                    GROUP BY employee_id) p
                   ON e.employee_id = p.employee_id;

-- Выплаты за работу в выходные дни.
CREATE OR replace VIEW hw.holidays_work AS
SELECT e.employee_id, e.firstname, e.surname, sum(wh.hours_worked) AS total_holiday_hours
FROM hw.current_staff_v e
         LEFT JOIN hw.work_hours wh ON e.employee_id = wh.employee_id
         LEFT JOIN hw.date dt ON wh.date = dt.date
WHERE wh.date BETWEEN current_date - 365 AND current_date
  AND dt.holiday = true
GROUP BY e.employee_id, e.firstname, e.surname;

-- Полная информация о сотрудниках.
CREATE OR replace VIEW hw.employee_full_info AS
SELECT e.employee_id,
       e.firstname,
       e.surname,
       e.hour_salary,
       hw.nice_date(e.birthday) as birthday,
       total_hours,
       total_holiday_hours,
       payment,
       hw.ndfl(payment)         as year_ndfl
FROM hw.current_staff_v e
         LEFT JOIN hw.holidays_work hw_ on e.employee_id = hw_.employee_id
         LEFT JOIN hw.year_paid_hours yph
                   on e.employee_id = yph.employee_id
         LEFT JOIN hw.year_payments yp
                   on e.employee_id = yp.employee_id;