import jinja2 as j2
from typing import Final
import pandas as pd
import psycopg2
from pandas.core.frame import DataFrame
import logging


# Data Virtuality Server Details
host: Final[str] = "cwk.vm"
port: Final[str] = "35432"
database: Final[str] = "datavirtuality"
sslmode: Final[str] = "disable"
uid: Final[str] = "admin"
pwd: Final[str] = "admin"
sql: Final[str] = 'SELECT * FROM "views.SampleOfData"'
FORMAT_STRING: Final[str] = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'


# psycopg2 connection string
con_string = "dbname={} user={} host={} password={} port={} sslmode={}".format(database, uid, host, pwd, port, sslmode)

conn = psycopg2.connect(con_string)
data = pd.read_sql_query(sql, conn)


def get_template_logger() -> logging.Logger:
    """
    Dedicated logger for Jinja template issues.

    Returns:
        logging.Logger
    """
    logger = logging.getLogger("jinja")  # template engine logger
    if not len(logger.handlers):
        fh = logging.FileHandler("logs/jinja_report.log", mode='w')
        fh.setLevel(logging.DEBUG)
        formatter = logging.Formatter(FORMAT_STRING)
        fh.setFormatter(formatter)
        logger.addHandler(fh)
    return logger


#########################################################
# setup the Jinja environment
j2env = j2.Environment(
    loader=j2.FileSystemLoader('templates'),  # folder to search
    autoescape=j2.select_autoescape(['j2']),  # file extension
    # defines behavior when there is an undefined variable in the jinja template
    undefined=j2.make_logging_undefined(logger=get_template_logger(), base=j2.Undefined),
    # undefined=my_make_logging_undefined(logger=get_template_logger(), base=j2.Undefined),  # used for debugging
)

#########################################################
# render section of the report
template_data = {
    "logo_link": 'https://datavirtuality.com/wp-content/uploads/2021/09/DV-Logo.svg',
    "col_names": data.columns,
    "data": data
}
template = j2env.get_template('template-jinja.html.j2')
report: str = template.render(template_data)

#########################################################
# Write the report to the file system
with open("report.html", "w") as f:
    f.write(report)
