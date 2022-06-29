"""
Test
"""

import unittest

import json
from functions.main.lambda_function import lambda_handler


class TestFunction(unittest.TestCase):
    def test_basic(self):
        query = {'words': ['犬', '犬種'], 'num': 20}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        res_data = json.loads(response['body'])
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(len(res_data['cwords']), 20)
    
    def test_not_exist_keyword(self):
        # "qwert" does not exist in word2vec model.
        query = {'words': ['qwert'], 'num': 10}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
    
    def test_not_enough_request(self):
        query = {'num': 10}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)

    def test_invalid_type_num_param(self):
        query = {'num': '10'}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
    
    def test_invalid_num_param(self):
        query = {'words': ['猫'], 'num': -10}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
    
    def test_invalid_type_words_param(self):
        query = {'words': '猫', 'num': 10}
        event = {
            'httpMethod': 'post',
            'body': json.dumps(query),
        }

        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 200)


if __name__ == '__main__':
    unittest.main()

