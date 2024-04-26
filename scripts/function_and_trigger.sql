------------------------------------------------------------------------------------
---------------------------------TECH-VIEWS-----------------------------------------
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

------------------------------------------------------------------------------------
--------------------------------------FUNCTIONS-------------------------------------
------------------------------------------------------------------------------------

-- Вычисляет НДФЛ, переводя доллары в рубли и назад
CREATE OR REPLACE FUNCTION hw.ndfl(payment numeric)
    RETURNS numeric
AS
$$
BEGIN
    -- 5'000'000 RUB to USD
    IF $1 <= 60000 THEN
        RETURN round($1 * 0.13, 2);
    ELSE
        RETURN round(60000 * 0.13 + ($1 - 60000) * 0.15, 2);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Вычисляет количество дней, которые сотрудник не работал за свой счет
CREATE OR REPLACE FUNCTION hw.count_days_off(e_id integer)
    RETURNS integer
AS
$$
BEGIN
    IF $1 NOT IN (SELECT employee_id FROM hw.employee) THEN
        RAISE 'Employee with id "%" is absent in database!', e_id USING ERRCODE = '02000';
    ELSE
        RETURN (SELECT COUNT(date)
                FROM hw.work_hours
                WHERE hour_type_id = 5
                  AND employee_id = $1);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Определяет по дате, праздник ли это
CREATE OR REPLACE FUNCTION hw.is_holiday(dt date)
    RETURNS boolean
AS
$$
BEGIN
    IF $1 IN (SELECT date
              FROM hw.date
              where holiday = true) THEN
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Приводит дату к привычному виду
CREATE OR REPLACE FUNCTION hw.nice_date(dt date)
    RETURNS text
AS
$$
BEGIN
    RETURN to_char(dt, 'DD-MM-YYYY');
END;
$$ LANGUAGE plpgsql;

-- Вычисляет текущее значение valid_from для сотрудника
CREATE OR REPLACE FUNCTION hw.get_valid_from(e_id integer, dt date)
    RETURNS date
AS
$$
BEGIN
    RETURN (SELECT distinct valid_from
            FROM hw.employee
            WHERE valid_from <= dt
              AND dt <= valid_to
              AND employee_id = e_id);
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------
--------------------------------------TRIGGERS--------------------------------------
------------------------------------------------------------------------------------
-- Вставка нового сотрудника, поддержка SCD2
CREATE OR REPLACE FUNCTION hw.staff_v_insert_row()
    RETURNS trigger AS
$emp_stamp$
BEGIN
    INSERT INTO hw.employee
    VALUES (NEW.*);
    RETURN OLD;
END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER staff_v_insert
    INSTEAD OF INSERT
    ON hw.current_staff_v
    FOR EACH ROW
EXECUTE FUNCTION hw.staff_v_insert_row();

-- Update сотрудника, поддержка SCD2(храним старые данные о сотруднике)
CREATE OR REPLACE FUNCTION hw.staff_v_update_row()
    RETURNS trigger AS
$emp_stamp$
BEGIN
    UPDATE hw.employee
    SET valid_to = current_date - 1
    WHERE employee_id = NEW.employee_id
      and valid_to > current_date;

    INSERT INTO hw.employee
    (employee_id, firstname, surname, birthday, work_type_id, hour_salary, employment_dt, valid_from, valid_to)
    VALUES (NEW.employee_id, NEW.firstname, NEW.surname, NEW.birthday, NEW.work_type_id, NEW.hour_salary,
            NEW.employment_dt, current_date, '2100-01-01');
    RETURN OLD;
END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER staff_v_update
    INSTEAD OF UPDATE
    ON hw.current_staff_v
    FOR EACH ROW
EXECUTE FUNCTION hw.staff_v_update_row();

-- Вставка рабочего дня, автоматическая поддержка внешнего ключа
CREATE OR REPLACE FUNCTION hw.hours_worked_v_insert_row()
    RETURNS trigger AS
$emp_stamp$
BEGIN
    INSERT INTO hw.work_hours(employee_id, employee_valid_from, date, hours_worked, hour_type_id)
    VALUES (NEW.employee_id, hw.get_valid_from(NEW.employee_id, NEW.date), NEW.date, NEW.hours_worked,
            NEW.hour_type_id);
    RETURN OLD;
END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER hours_worked_v_insert
    INSTEAD OF INSERT
    ON hw.work_hours_v
    FOR EACH ROW
EXECUTE FUNCTION hw.hours_worked_v_insert_row();
