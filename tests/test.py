import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker


@pytest.fixture(scope='module')
def db_engine():
    engine = create_engine('postgresql://postgres:1234@localhost:5432/postgres')
    return engine


@pytest.fixture(scope='module')
def db_session(db_engine):
    Session = sessionmaker(bind=db_engine)
    session = Session()
    yield session
    session.close()


def test_connection(db_session):
    result = db_session.execute(text('SELECT 1'))
    assert result.scalar() == 1


def test_tables_exist(db_session):
    tables = ['employee', 'work_type', 'premium']
    for table in tables:
        result = db_session.execute(text(f"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'hw' AND table_name = '{table}')"))


def test_work_hours_schema(db_session):
    expected_schema = {
        'work_hour_id': 'integer',
        'employee_id': 'integer',
        'employee_valid_from': 'date',
        'date': 'date',
        'hours_worked': 'numeric',
        'hour_type_id': 'integer'
    }
    result = db_session.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'hw' AND table_name = 'work_hours'"))
    actual_schema = {column: dtype for column, dtype in result}
    assert actual_schema == expected_schema


def test_employee_schema(db_session):
    expected_schema = {
        'employee_id': 'integer',
        'firstname': 'text',
        'surname': 'text',
        'birthday': 'date',
        'work_type_id': 'integer',
        'hour_salary': 'numeric',
        'employment_dt': 'date',
        'valid_from': 'date',
        'valid_to': 'date'
    }
    result = db_session.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'hw' AND table_name = 'employee'"))
    actual_schema = {column: dtype for column, dtype in result}
    assert actual_schema == expected_schema


def test_premium_schema(db_session):
    expected_schema = {
        'premium_id': 'integer',
        'employee_id': 'integer',
        'employee_valid_from': 'date',
        'date': 'date',
        'payment': 'numeric',
        'premium_type_id': 'integer'
    }
    result = db_session.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'hw' AND table_name = 'premium'"))
    actual_schema = {column: dtype for column, dtype in result}
    assert actual_schema == expected_schema


def test_useful_script(db_session):
    try:
        with open('../scripts/select_count_script.sql', 'r') as file:
            sql_script = file.read()
        result = db_session.execute(text(sql_script))
        # Check that the table has the correct columns and data types
        assert result.keys() == ['table_name', 'cnt']
        expected_output = [('employee', 12), ('work_type', 7), ('work_hour_type', 6)]
        assert list(result) == expected_output

    except FileNotFoundError:
        assert False, "File '../scripts/useful_script.sql' not found"