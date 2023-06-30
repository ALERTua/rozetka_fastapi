import asyncio
import os
import json
import pprint
from collections import namedtuple
from aiohttp_retry import ExponentialRetry, RetryClient
from cashews import cache
from fastapi import FastAPI, HTTPException
from influxdb_client.client.influxdb_client_async import InfluxDBClientAsync
from global_logger import Log

LOG = Log.get_logger()

app = FastAPI()

INFLUXDB_URL = os.getenv('INFLUXDB_URL')
INFLUXDB_TOKEN = os.getenv('INFLUXDB_TOKEN')
INFLUXDB_ORG = os.getenv('INFLUXDB_ORG')
INFLUXDB_BUCKET = os.getenv('INFLUXDB_BUCKET')

INFLUX_KWARGS_ASYNC = dict(url=INFLUXDB_URL, token=INFLUXDB_TOKEN, org=INFLUXDB_ORG,
                           client_session_type=RetryClient,
                           timeout=600_000, client_session_kwargs={"retry_options": ExponentialRetry(attempts=3)})

Record = namedtuple("Record", ('date', 'value'))


# @app.get("/")
# async def root():
#     return {}


@cache(ttl="12h")
async def get_values(id_: int, field: str):
    LOG.trace()
    async with InfluxDBClientAsync(**INFLUX_KWARGS_ASYNC) as client:
        ready = await client.ping()
        if not ready:
            LOG.error(f"InfluxDB NOT READY")
            raise HTTPException(status_code=502, detail="Database error. Please contact Telegram @ALERTua")

        query_api = client.query_api()
        query = f' from(bucket:"{INFLUXDB_BUCKET}") ' \
                f' |> range(start: -3y)' \
                f' |> filter(fn: (r) => r["id_"] == "{id_}")' \
                f' |> filter(fn: (r) => r["_field"] == "{field}")' \
                f' |> aggregateWindow(every: 12h, fn: mean, createEmpty: false)'
        response = await query_api.query(query=query, org=INFLUXDB_ORG)
        # response = await query_api.query_raw(query=query, org=INFLUXDB_ORG)

        records = response.to_values(columns=['_time', '_value'])

        output = []
        for record in records:
            record_ = Record(*record)
            output.append(record_)
        return {i.date.timestamp() * 1000: i.value for i in output}


@cache(ttl="12h")
async def get_data_by_id(id_: int):
    LOG.trace()
    async with InfluxDBClientAsync(**INFLUX_KWARGS_ASYNC) as client:
        ready = await client.ping()
        if not ready:
            LOG.error(f"InfluxDB NOT READY")
            raise HTTPException(status_code=502, detail="Database error. Please contact Telegram @ALERTua")

        query_api = client.query_api()
        query = f'''
import "influxdata/influxdb/schema"
from(bucket: "{INFLUXDB_BUCKET}")
    |> range(start: -3y)
    |> filter(fn: (r) => r["id_"] == "{id_}")
    |> aggregateWindow(every: 12h, fn: mean, createEmpty: false)
    |> sort(columns: ["_time"])
    |> schema.fieldsAsCols()
'''
        response = await query_api.query(query=query, org=INFLUXDB_ORG)
        if not response:
            LOG.yellow(f"Empty response on {id_}")
            output = []
        else:
            # response = await query_api.query_raw(query=query, org=INFLUXDB_ORG)
            # json_ = response.to_json(["_stop", "discount", "old_price", "price"])
            output = json.loads(response.to_json())
            erase = ('result', 'table', '_measurement', 'id_', '_start', '_stop')
            for item in output:
                for field in erase:
                    item.pop(field, None)
            LOG.green(f"{id_}: Returning\n{pprint.pformat(output)}")
        return output


@app.get("/price/{id_}")
async def get_price(id_: int):
    return await get_values(id_=id_, field='price')


@app.get("/discount/{id_}")
async def get_discount(id_: int):
    return await get_values(id_=id_, field='discount')


@app.get("/price_old/{id_}")
async def get_price_old(id_: int):
    return await get_values(id_=id_, field='old_price')


@app.get("/get/{id_}")
async def get_data(id_: int):
    return await get_data_by_id(id_=id_)


if __name__ == '__main__':
    a = asyncio.run(get_data_by_id(100044884))
    pass
