"""
Fetch collocation words
"""

import io
import os
import re
import json
import pickle
import boto3


# with open('model/model.pkl', 'rb') as fp:
#     model = pickle.load(fp)
s3_client = boto3.client('s3')
s3_object = s3_client.get_object(Bucket=os.environ['MODEL_BUCKET'], Key=os.environ['MODEL_KEY'])
model_data = io.BytesIO(s3_object['Body'].read())
model = pickle.load(model_data)

regexp = re.compile(r'[\[\]]')


def bad_request(status:int, message:str):
    headers = {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        # 'Access-Control-Allow-Credentials': 'true',
    }
    return {
        'statusCode': status,
        'headers': headers,
        'body': message 
    }

def search_cwords(queries, n_results):
    results = model.most_similar(queries, topn=n_results)
    results = list(map(lambda w: (regexp.sub('', w[0]), w[1]), results))
    return results

def handler_for_get(event, _context):
    queryStr = event['queryStringParameters']
    if queryStr is None:
        return bad_request(400, 'query not found')
    if 'words' in queryStr:
        queries = queryStr['words'].split(' ')
    else:
        return bad_request(400, 'query is invalid ("words" query not found')

    if 'num' in queryStr:
        n_results = queryStr['num']
        if not isinstance(n_results, int):
            return bad_request(400, 'num must be integer')
        if n_results <= 0:
            return bad_request(400, 'num must be positive')
    else:
        n_results = 10
    
    try:
        cwords = search_cwords(queries, n_results)
    except KeyError as e:
        return bad_request(400, f'{e}')
    except Exception:
        return bad_request(500, 'error was occured in searching cwords')

    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        # 'Access-Control-Allow-Credentials': 'true',
    }
    body = {
        'cwords': cwords
    }
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(body)
    }

def handler_for_post(event, _context):
    body = json.loads(event['body'])
    if 'words' in body:
        queries = body['words']
    else:
        return bad_request(400, 'query is invalid ("words" key not found)')
    
    if 'num' in body:
        n_results = body['num']
        if not isinstance(n_results, int):
            return bad_request(400, 'num must be integer')
        if n_results <= 0:
            return bad_request(400, 'num must be positive')
    else:
        n_results = 10
    
    try:
        cwords = search_cwords(queries, n_results)
    except KeyError as e:
        return bad_request(400, f'{e}')
    except Exception:
        return bad_request(500, 'error was occured in searching cwords')
    
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        # 'Access-Control-Allow-Credentials': 'true',
    }
    body = {
        'cwords': cwords
    }
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    print(event)
    
    http_method = event['httpMethod']
    if  http_method.lower() != 'get' and http_method.lower() != 'post':
        return bad_request(400, f'{http_method} not allowed')
    
    if http_method.lower() == 'get':
        return handler_for_get(event, context)
    else:
        # else case is only 'post'
        return handler_for_post(event, context)
