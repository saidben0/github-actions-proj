import logging
import botocore
import boto3
import pymupdf
from datetime import datetime
import re
from helper_functions import *
from typing import Optional
import math
import os

# Logger information
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):

    #################### Retrieve variables ####################
    try:
        print(event)
       
        message = event['Records'][0]
        message_attributes = message['messageAttributes']
        sqs_message_id = message['messageId']
        project_name = message_attributes['application']['stringValue']
        s3_loc = message_attributes['s3_location']['stringValue']
        model_id = message_attributes['model_id']['stringValue']
        receipt_handle = message['receiptHandle']

        prompt = Prompt(
            identifier = message_attributes['prompt_id']['stringValue'],
            ver = message_attributes.get('prompt_version', {}).get('stringValue', None)
        )

    except KeyError as e:
        logging.error(f"The SQS message has missing attribute: {e}.")
        raise

    table_name = os.environ['DDB_TABLE_NAME']
    queue_url=os.environ['QUEUE_URL']
    # table_name="aws-proserve-land-doc"

    system_prompt = Prompt(
        identifier = message_attributes.get('system_prompt_id', {}).get('stringValue', None),
        ver = message_attributes.get('system_prompt_version', {}).get('stringValue', None)
    )

    #################### Extract file loc details ####################
    bucket_name = s3_loc.split('/')[2]
    s3_key = s3_loc.split('/', 3)[3:][0]
    file_id = s3_loc.split('/')[-1].split('.')[0]

    #################### Read file from S3 ####################
    try:
        logging.info(f"s3_key: {s3_key}")
        logging.info(f"Reading file {file_id} from bucket {bucket_name}")
        mime, body = retrievePdf(bucket_name, s3_key)

    except Exception as e:
        logging.error(f"Error getting file from S3: {e}")
        raise

    #################### Convert PDF to model input ####################
    try:
        logging.info(f"Converting PDF to byte: {file_id}")
        bytes_inputs = convertS3Pdf(mime, body)

        logging.info(f"Number of pages in the pdf: {len(bytes_inputs)}")

    except Exception as e:
        logging.error(f"Error reading the file: {e}")
        raise

    #################### Retrieve Prompt from Bedrock ####################
    try:
        logging.info(f"Retrieving prompt {prompt.identifier} from Bedrock...")
        prompt.text, prompt.ver = retrieve_bedrock_prompt(prompt.identifier, prompt.ver)

    except Exception as e:
        logging.error(f"Error retrieving prompt: {e}")
        raise

    if system_prompt.identifier:
        try:
            logging.info(f"Retrieving system prompt {system_prompt.identifier} from Bedrock...")
            system_prompt.text, system_prompt.ver = retrieve_bedrock_prompt(system_prompt.identifier, system_prompt.ver)

        except Exception as e:
            logging.error(f"Error retrieving system prompt: {e}")
            raise

    #################### LLM call ####################
    # Split the images to chunks of 20
    if len(bytes_inputs) <= 20:
        num_chunk = 1
        logging.info(f"There are {len(bytes_inputs)} pages in the document. Processing all pages in one chunk.")
    elif len(bytes_inputs) > 20:
        num_chunk = math.ceil(len(bytes_inputs)/20)
        logging.info(f"Splitting the images into {num_chunk} chunks...")

    grouped_bytes_input = [bytes_inputs[i:i+20] for i in range(0, len(bytes_inputs), 20)]

    exception_flag = False

    for i, byte_input in enumerate(grouped_bytes_input):
        logging.info(f"Extracting land description for chunk {i+1}...")
        ingestion_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        try:
            model_response = call_llm(byte_input, model_id, prompt, system_prompt)
            # response_text = model_response["output"]["message"]["content"][0]["text"]
            # print(f"response_text for chunk {i+1}: ----------------\n {response_text}")

        except Exception as e:
            logging.error(f"Error making LLM call: {e} Storing error details to DynamoDB Table: {table_name}")
            update_ddb_table(table_name, project_name, sqs_message_id, file_id, ingestion_time, prompt, system_prompt, model_id, num_chunk, chunk_id=i+1, exception=e)
            exception_flag = True
            raise

        try:
            logging.info(f"Storing results of chunk {i+1} to DynamoDB Table: {table_name}")
            update_ddb_table(table_name, project_name, sqs_message_id, file_id, ingestion_time, prompt, system_prompt, model_id, num_chunk, chunk_id=i+1, model_response=model_response)
        except Exception as e:
            logging.error(f"Error saving to DynamoDB table: {e}")
            raise

    ################### Delete received message from queue if there is no error in the LLM-calling step ####################
    if not exception_flag:
        try:
            logging.info("Document successfully processed. Deleting SQS message from queue...")
            sqs = boto3.client('sqs')
            sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=receipt_handle
            )
        except Exception as e:
            logging.error(f"Error deleting SQS message from queue: {e}")
            raise

    return {
        'statusCode': 200,
        'body': f'File {file_id} processed successfully!'
    }
