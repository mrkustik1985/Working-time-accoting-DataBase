DROP SCHEMA IF EXISTS hw CASCADE;
CREATE SCHEMA hw;

------------------------------------------------------------------------------------
--------------------------------------TABLES----------------------------------------
------------------------------------------------------------------------------------

CREATE TABLE hw.work_type
(
    work_type_id       SERIAL PRIMARY KEY,
    free_schedule      boolean NOT NULL,
    schedule_id        integer,
    week_working_hours numeric
);

CREATE SEQUENCE hw.employee_id_seq as integer increment by 1;

CREATE TABLE hw.employee
(
    employee_id   integer NOT NULL,
    firstname     text    NOT NULL,
    surname       text    NOT NULL,
    birthday      date,
    work_type_id  integer NOT NULL,
    hour_salary   numeric NOT NULL,
    employment_dt date,
    valid_from    date DEFAULT '1970-01-01',
    valid_to      date    NOT NULL,
    PRIMARY KEY (employee_id, valid_from),
    FOREIGN KEY (work_type_id) REFERENCES hw.work_type (work_type_id) ON DELETE SET NULL
);

CREATE TABLE hw.work_hour_type
(
    hour_type_id SERIAL PRIMARY KEY,
    description  text    NOT NULL,
    paid         boolean not NULL
);

CREATE TABLE hw.work_hours
(
    work_hour_id        SERIAL PRIMARY KEY,
    employee_id         integer NOT NULL,
    employee_valid_from date DEFAULT '1970-01-01',
    date                date    NOT NULL,
    hours_worked        numeric NOT NULL,
    hour_type_id        integer NOT NULL,
    FOREIGN KEY (hour_type_id) REFERENCES hw.work_hour_type (hour_type_id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id, employee_valid_from) REFERENCES hw.employee (employee_id, valid_from) ON DELETE SET NULL
);

CREATE TABLE hw.premium_type
(
    premium_type_id SERIAL PRIMARY KEY,
    description     text NOT NULL
);

CREATE TABLE hw.premium
(
    premium_id          SERIAL PRIMARY KEY,
    employee_id         integer NOT NULL,
    employee_valid_from date    NOT NULL,
    date                date    NOT NULL,
    payment             numeric NOT NULL,
    premium_type_id     integer NOT NULL,
    FOREIGN KEY (premium_type_id) REFERENCES hw.premium_type (premium_type_id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id, employee_valid_from) REFERENCES hw.employee (employee_id, valid_from) ON DELETE SET NULL
);

CREATE TABLE hw.date
(
    date    date PRIMARY KEY,
    weekday smallint not NULL,
    holiday boolean  not NULL
);