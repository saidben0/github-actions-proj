import os
import logging
#from .prompts import *
import botocore
import boto3
import pymupdf
from datetime import datetime
import re
from helper_functions.main import *

S3_URI = os.environ['S3_URI']
DDB_TABLE_NAME = os.environ['DDB_TABLE_NAME']
PROJECT_NAME = os.environ['PROJECT_NAME']
PROMPT_ID = os.environ['PROMPT_ID']
PROMPT_VER = os.environ['PROMPT_VER']
SYSTEM_PROMPT_ID = os.environ['PROMPT_ID']
SYSTEM_PROMPT_VER = os.environ['PROMPT_VER']

# # S3_URI = 's3://enverus-courthouse-dev-chd-plants/tx/austin/000d/000deb93-d254-45ec-825e-d6cb094749dd.pdf'
# S3_URI = 's3://enverus-courthouse-dev-chd-plants/tx/angelina/502d/502d1735-8162-4fed-b0a9-d12fcea75759.pdf'
# DDB_TABLE_NAME = 'aws-proserve-land-doc'
# PROJECT_NAME = 'land-doc-processing'
# PROMPT_ID = '9OBEWDH99Y'
# PROMPT_VER = '1'
# SYSTEM_PROMPT_ID = '9LCMX94WY0'
# SYSTEM_PROMPT_VER = '1'

# Logger information
logger = logging.getLogger()
logger.setLevel("INFO")
    
def lambda_handler(event, context):
    
    # sqs_message_id = event['ID']
    sqs_message_id = 'test-sqs-id'
    
    bucket_name = S3_URI.split('/')[2]
    s3_key = S3_URI.split('/', 3)[3:][0]
    file_name = S3_URI.split('/')[-1].split('.')[0]
    
    ##### Read file from S3 #####
    try:
        logging.info(f"Reading file from S3: {file_name}")
        mime, body = retrievePdf(bucket_name, s3_key)
    
    except Exception as e:
        logging.error(f"Error getting file from S3: {e}")
    
    ##### Convert PDF to model input #####
    try:
        logging.info(f"Processing file: {file_name}")
        bytes_inputs = convertS3Pdf(mime, body)
        
        logging.info(f"Number of pages in the pdf: {len(bytes_inputs)}")

    except Exception as e:
        logging.error(f"Error reading the file: {e}")
    
    ##### Retrieve Prompt from Bedrock #####
    try:
        logging.info(f"Retrieving prompt from Bedrock...")
        prompt, system_prompt = retrieve_prompts(PROMPT_ID, PROMPT_VER, SYSTEM_PROMPT_ID, SYSTEM_PROMPT_VER)
    
    except Exception as e:
        logging.error(f"Error retrieving prompts: {e}")
        
    ##### LLM call #####
    try:
        logging.info("Extracting land description...")
        model_response = call_llm(bytes_inputs, prompt, system_prompt, model_id)
    
    except Exception as e:
        logging.error(f"Error making LLM call: {e}")
    
    ##### Save output to DynamoDB #####
    try:              
        logging.info(f"Storing results to DynamoDB Table: {DDB_TABLE_NAME}")
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        update_ddb_table(DDB_TABLE_NAME, PROJECT_NAME, sqs_message_id, file_name, current_time, model_response=model_response, chunk_id=1)

    except Exception as e:
        logging.error(f"Error saving LLM output to DynamoDB: {e}")
    
    return {
        'statusCode': 200,
        'body': f'File {file_name} processed successfully!'
    }
