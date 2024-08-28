import os
import logging
#from .prompts import *
import multiprocessing 
from joblib import Parallel, delayed
import botocore
import boto3
from decimal import Decimal
import math
import pymupdf
from datetime import datetime
import re

bucket_name = os.environ['BUCKET_NAME']
# file_key = os.environ['FILE_PATH']
# bucket_name = 'enverus-courthouse-dev-chd-plants'
file_key = 'tx/angelina/502d/502d1735-8162-4fed-b0a9-d12fcea75759.pdf'

model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0"

# Logger information
logger = logging.getLogger()
logger.setLevel("INFO")

def retrievePdf(bucket, s3_key):
    s3 = boto3.client('s3')

    response = s3.get_object(Bucket=bucket_name, Key=s3_key)
    mime = response["ContentType"]
    body = response["Body"]

    return mime, body
    
def convertS3Pdf(mime, body):
    bytes_outputs = []
    
    doc = pymupdf.open(mime, body.read())  # open document
    # doc = pymupdf.open(file)
    for page in doc:  # iterate through the pages
        pix = page.get_pixmap(dpi=100)  # render page to an image
        pdfbytes=pix.tobytes()
        bytes_outputs.append(pdfbytes)
    return bytes_outputs

def convertPdf(file):
    bytes_outputs = []
    
    # doc = pymupdf.open(mime, body.read())  # open document
    doc = pymupdf.open(file)
    for page in doc:  # iterate through the pages
        pix = page.get_pixmap(dpi=100)  # render page to an image
        pdfbytes=pix.tobytes(output='png')
        bytes_outputs.append(pdfbytes)
    return bytes_outputs
    
# def applyParallelPandas(func, df, **kwargs):
#     cpu_count = multiprocessing.cpu_count()
#     chunk_size = len(df)//cpu_count
#     print(cpu_count, chunk_size)
#     datasets = [df.iloc[i:i+chunk_size] for i in range(0,len(df),chunk_size)]
#     retLst = Parallel(n_jobs=cpu_count)(delayed(lambda x: x.apply(func, **kwargs))(df) for df in datasets)
#     return pd.concat(retLst)


# def update_item(contract_name, question_hash, context_completness, faithfulness, answer_relevancy, faithfulness_short_answer, answer_relevancy_short_answer, dynamod_table, region_name):
#     #update specified faq table with metrics from evaluation_set
#     #time = BatchData.to_iso_format(datetime.utcnow())

#     try:
#         if math.isnan(faithfulness):
#             faithfulness = 0
#         if math.isnan(answer_relevancy):
#             answer_relevancy = 0
#         if math.isnan(faithfulness_short_answer):
#             faithfulness_short_answer = 0
#         if math.isnan(answer_relevancy_short_answer):
#             answer_relevancy_short_answer = 0
#         response = dynamod_table.update_item(
#             Key={
#                 "contract_name": contract_name,
#                 "question_hash": question_hash,
#             },
#             UpdateExpression="SET context_completness = :cc, faithfulness = :f, answer_relevancy = :ar, faithfulness_short_answer = :fs, answer_relevancy_short_answer = :ars",
#             ExpressionAttributeValues={
#                 ":cc": context_completness,
#                 ":f": Decimal(str(faithfulness)),
#                 ":ar": Decimal(str(answer_relevancy)),
#                 ":fs": Decimal(str(faithfulness_short_answer)),
#                 ":ars": Decimal(str(answer_relevancy_short_answer))
#             }
#         )
#         #print(response)
#     except Exception as e:
#         logger.info(f"Error updating an item: {e}")

# def update_table(evaluation_set, table_name, region_name):
#     logger.info(f"region: {region_name} | table: {table_name} updating with metrics")
#     dynamodb = boto3.resource("dynamodb", region_name=region_name)
#     dynamod_table = dynamodb.Table(table_name)
    
#     for i in range(1, len(evaluation_set)):
#         e = evaluation_set.iloc[i]
#         update_item(e['contract_name'],e['question_hash'],e['context_completness'], e['faithfulness'], e['answer_relevancy'], e['faithfulness_short_answer'], e['answer_relevancy_short_answer'], dynamod_table, region_name)

def update_ddb_table(table_name, project_name, sqs_message_id, file_id, current_time, model_response=None, chunk_id=None, exception='null', flag_status=False):
    """
    Output the model response to DynamoDB Table.
    """
    dynamodb = boto3.client('dynamodb')

    if model_response is not None:
        response_text = model_response["output"]["message"]["content"][0]["text"]
        final_output = re.search(r'<final_output>(.*?)</final_output>', response_text, re.DOTALL).group(1).strip()

        latency = model_response["metrics"]["latencyMs"]
        input_token = model_response["usage"]["inputTokens"]
        output_token = model_response["usage"]["outputTokens"]

        response = dynamodb.put_item(
            TableName=table_name,
            Item={
            "project_name": {"S": project_name},
            "chunk_id": {"N": str(chunk_id)},
            "sqs_message_id": {"S": sqs_message_id},
            "document_id": {"S": file_id.split('.')[0]},
            "ingestion_time": {"S": current_time},
            "model_response": {"S": final_output},
            "latency": {"N": str(latency)},
            "input_token": {"N": str(input_token)},
            "output_token": {"N": str(output_token)},
            "exception": {"S": exception},
            "FLAG": {"BOOL": flag_status}
        })
    else:
        response = dynamodb.put_item(
            TableName=table_name,
            Item={
            "project_name": {"S": project_name},
            "chunk_id": {"N": str(chunk_id)},
            "sqs_message_id": {"S": sqs_message_id},
            "document_id": {"S": file_id.split('.')[0]},
            "ingestion_time": {"S": current_time},
            "exception": {"S": exception},
            "FLAG": {"BOOL": flag_status}
        })

    return response

def retrieve_prompts(prompt_id, prompt_ver, sys_prompt_id, sys_prompt_ver):
    client = boto3.client('bedrock-agent')

    prompt_response = client.get_prompt(promptIdentifier=prompt_id,
                                 promptVersion=prompt_ver)

    prompt = prompt_response['variants'][0]['templateConfiguration']['text']['text']


    system_prompt_response = client.get_prompt(promptIdentifier=sys_prompt_id,
                                               promptVersion=sys_prompt_ver)

    system_prompt = system_prompt_response['variants'][0]['templateConfiguration']['text']['text']
    
    return prompt, system_prompt

def call_llm(bytes_inputs, prompt, system_prompt, model_id):
    bedrock_runtime = boto3.client("bedrock-runtime", region_name="us-east-1")

    
    content_input = []
    for bytes_input in bytes_inputs:
        content_input.append({"image": {"format": "png", "source": {"bytes": bytes_input}}})

    content_input.append({"text": prompt})

    messages = [
        {
            "role": "user",
            "content": content_input,
        }
    ]

    response = bedrock_runtime.converse(
        modelId=model_id,
        messages=messages,
        system=[
                {"text":system_prompt
                }],
        inferenceConfig={
            'temperature':0,
            'topP': 0.8
        }
    )
    
    return response
    
def main(PROMPT, IMAGE_NAME, SYSTEM_PROMPT, bucket_name, file_key, region_name=None):
    
    tract_info = []
    
    logging.info(f"Processing image: {IMAGE_NAME}")
    # mime, body = retrievePdf(bucket_name, file_key)
    bytes_inputs = convertPdf(IMAGE_NAME)
    
    print(f"Number of pages in the pdf: {len(bytes_inputs)}")
    content_input = []
    for bytes_input in bytes_inputs:
        content_input.append({"image": {"format": "png", "source": {"bytes": bytes_input}}})
    
    content_input.append({"text": PROMPT})
    
    # with open(IMAGE_NAME, "rb") as f:
    #     image = f.read()
    # images = convertPdf(IMAGE_NAME)
    # logging.info(f"Converted lines: {images}")
    
    bedrock_runtime = boto3.client("bedrock-runtime", region_name="us-east-1")

    messages = [
		{
			"role": "user",
			"content": content_input,
		}
	]
    
    response = bedrock_runtime.converse(
        modelId=model_id,
        system=[
                {"text":SYSTEM_PROMPT
                }],
        messages=messages,
        inferenceConfig={
			'temperature':0,
		}
    )
    response_text = response["output"]["message"]["content"][0]["text"]
    tract_info.append(response_text)
    
    print(response_text)

    return response_text

def main_ceciliss(project_name, table_name, PROMPT, SYSTEM_PROMPT, file_id, bucket_name, file_key, region_name=None, sqs_message_id='test-sqs-id', model_id='anthropic.claude-3-5-sonnet-20240620-v1:0'):

    try:
        logging.info(f"Processing file: {file_id}")
        # mime, body = retrievePdf(bucket_name, file_key)
        bytes_inputs = convertPdf(file_id)

        logging.info(f"Number of pages in the pdf: {len(bytes_inputs)}")

    except Exception as e:
        print(f"Error reading the pdf: {e}")
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        # update_ddb_table(table_name, project_name, sqs_message_id, file_id, current_time, exception=e, flag_status=True)

    try:
        # Max 20 images in one single call to Sonnet
        if len(bytes_inputs) <= 20:
            logging.info("Extracting land description...")
            model_response = call_llm(bytes_inputs, PROMPT, model_id, SYSTEM_PROMPT)
            
            response_text = model_response["output"]["message"]["content"][0]["text"]
            print(f"response_text: ----------------\n {response_text}")
            
            # logging.info(f"Storing results to DynamoDB Table: {table_name}")
            # current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            # update_ddb_table(table_name, project_name, sqs_message_id, file_id, current_time, model_response=model_response, chunk_id=1)

        elif len(bytes_inputs) > 20:
            # split the images into groups of 20
            grouped_bytes_input = [bytes_inputs[i:i+20] for i in range(0, len(bytes_inputs), 20)]

            for i in range(len(grouped_bytes_input)):
                logging.info(f"Extracting land description for chunk {i+1}...")
                model_response = call_llm(grouped_bytes_input[i], PROMPT, model_id, SYSTEM_PROMPT)
                response_text = model_response["output"]["message"]["content"][0]["text"]
                print(f"response_text for chunk {i+1}: ----------------\n {response_text}")

                # logging.info(f"Storing results of chunk {i+1} to DynamoDB Table: {table_name}")
                # current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                # update_ddb_table(table_name, project_name, sqs_message_id, file_id, current_time, model_response=model_response, chunk_id=i+1)

    except Exception as e:
        exception = e
        flag_status = True
        print(f"Error processing the pdf: {e}")


#     print(f"latency: -------------------------\n{latency}")
#     print(f"input_token: -------------------------\n{input_token}")
#     print(f"output_token: -------------------------\n{output_token}")
#     print(f"ingestion_time: -------------------------\n{current_time}")
#     print(f"Response_text: --------------------\n{response_text}")
#     print(f"land_desc: --------------------\n{land_desc}")

    # return response_text
