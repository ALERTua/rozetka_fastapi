import os
from collections import namedtuple

from aiohttp_retry import ExponentialRetry, RetryClient
from fastapi import FastAPI, HTTPException
from global_logger import Log
from influxdb_client.client.influxdb_client_async import InfluxDBClientAsync

log = Log.get_logger()

app = FastAPI()

INFLUXDB_URL = os.getenv('INFLUXDB_URL')
INFLUXDB_TOKEN = os.getenv('INFLUXDB_TOKEN')
INFLUXDB_ORG = os.getenv('INFLUXDB_ORG')
INFLUXDB_BUCKET = os.getenv('INFLUXDB_BUCKET')

INFLUX_KWARGS_ASYNC = dict(url=INFLUXDB_URL, token=INFLUXDB_TOKEN, org=INFLUXDB_ORG,
                           client_session_type=RetryClient,
                           timeout=600_000, client_session_kwargs={"retry_options": ExponentialRetry(attempts=3)})

Record = namedtuple("Record", ('date', 'price'))


# @app.get("/")
# async def root():
#     return {}


@app.get("/get/{id_}")
async def get_id(id_: int):
    log.trace()
    async with InfluxDBClientAsync(**INFLUX_KWARGS_ASYNC) as client:
        ready = await client.ping()
        if not ready:
            log.error(f"InfluxDB NOT READY")
            raise HTTPException(status_code=502, detail="Database error. Please contact Telegram @ALERTua")

        query_api = client.query_api()
        query = f' from(bucket:"{INFLUXDB_BUCKET}") ' \
                f' |> range(start: -100y)' \
                f' |> filter(fn: (r) => r["_measurement"] == "{id_}")' \
                f' |> filter(fn: (r) => r["_field"] == "price")' \
                f' |> aggregateWindow(every: 1d, fn: mean, createEmpty: false)'
        response = await query_api.query(query=query, org=INFLUXDB_ORG)
        # response = await query_api.query_raw(query=query, org=INFLUXDB_ORG)

        records = response.to_values(columns=['_time', '_value'])

        output = []
        for record in records:
            record_ = Record(*record)
            output.append(record_)
        return {i.date.timestamp(): i.price for i in output}
