from helper_functions import *
import sys
from multiprocessing import Process, Manager
import json
import os
import boto3
from datetime import datetime

# Logger information
logger = logging.getLogger()
logger.setLevel("INFO")

# Read environment variables
queue_url = os.environ.get('QUEUE_URL')
dest_bucket = os.environ.get('BATCH_DATA_BUCKET')
# TODO: add role ARN from ENV VAR

def lambda_function(event, context):
    s3 = boto3.client('s3')
    sqs = boto3.client('sqs')

    data_folder = f"{datetime.now().strftime('%Y-%m-%d-%H-%M-%S')}"

    EXPECTED = 1000
    queue_arr = []
    doc_arr = []
    # create array of SQS queue message with ReceiptHandle
    # quit if the ApproximateNumberOfMessages of the first record is less than 1000
    try:
    # checking if there are required messages
        logging.info("Checking # of message in the queue...")   
        response = sqs.get_queue_attributes(
                QueueUrl=queue_url,
                AttributeNames=[ 'All' ],
        )
        attrib = response['Attributes']['ApproximateNumberOfMessages']
        logging.info(f"ApproximateNumberOfMessages: {attrib}")
        if ( int(attrib) < EXPECTED):
            logging.info("Not enough messages for batch inference")   
            sys.exit(0)

        logging.info("Rceiving SQS message from queue...")   
        msg_count = 0
        
        msg_attributes = {}
        
        # one receive_message call can receive up to 10 messages a time 
        # so we will contine to call if we haven't received the EXPECTED number yet
        # note we could receive a few more messages depending on how many messages in the last call
        while (msg_count < EXPECTED):
            logging.info(f"Calling receive_message: messages received so far = {msg_count}")
            response = sqs.receive_message(
                QueueUrl=queue_url,
                MaxNumberOfMessages=10,
                MessageAttributeNames=['All']
            )

            # add up to 10 messages to the array
            try:
                messages = response['Messages']
                num_messages = len(messages)
            except KeyError:
                logging.log("No more records, exit loop")
                num_messages = 0
            for j in range(0, num_messages):
                try:
                    message = messages[j]
                except KeyError:
                    logging.error("Error in receive message, exit normally")
                    raise
                else:
                    try:
                        msg_count = msg_count + 1
                        sqs_message_id = message['MessageId']
                        logging.info(f"sqs_message_id: {j} - {sqs_message_id}")
                        receipt_handle = message['ReceiptHandle']
                        message_attributes = message['MessageAttributes']
                        project_name = message_attributes['application']['StringValue']
                        s3_loc = message_attributes['s3_location']['StringValue']
                        file_id = s3_loc.split('/')[-1].split('.')[0]
                        #model_id = message_attributes['model_id']['StringValue']
                        prompt_id = message_attributes['prompt_id']['StringValue']
                        prompt_ver = message_attributes.get('prompt_version', {}).get('StringValue', None)
                        system_prompt_id = message_attributes.get('system_prompt_id', {}).get('stringValue', None)
                        system_prompt_ver = message_attributes.get('system_prompt_version', {}).get('stringValue', None)

                        msg_attributes[file_id] = {
                            "sqs_message_id": sqs_message_id,
                            "prompt_id": prompt_id,
                            "prompt_ver": prompt_ver,
                            "system_prompt_id": system_prompt_id,
                            "system_prompt_ver": system_prompt_ver,
                            }

                        doc_arr.append(s3_loc)
                        queue_arr.append(receipt_handle)

                    except KeyError as e:
                        logging.error(f"Error receiving SQS message from queue: {e}")
                        raise
  
    except Exception as e:
        logging.error(f"Error receiving SQS message from queue: {e}")
        sys.exit(0)
    

    # TODO:  add logic to determine the model ID
    
    logging.info("Finish reading SQS messages.")
    
    logging.info("Start processing data.")
    
    with Manager() as manager:
        try:
            metadata_dict = manager.dict(msg_attributes)
            processes = []

            p = Process(target=parallel_enabled, args=(doc_arr, metadata_dict, dest_bucket, data_folder, ))
            processes.append(p)
            p.start()

            for p in processes:
                p.join()

            metadata = dict(metadata_dict)
            metadata_temp_loc = '/tmp/metadata.json'

            with open(metadata_temp_loc, 'w') as f:
                json.dump(metadata, f, indent=4)

        except Exception as e:
            logging.error(f"Error processing data: {e}")

        try:
            logging.info(f"Uploading metadata.json to {dest_bucket}")
            upload_to_s3(metadata_temp_loc, dest_bucket, f'{data_folder}/metadata')
        except Exception as e:
            logging.error(f"Error uploading metadata.json: {e}")
    
    logging.info("Finish processing data.")
    logging.info("Creating Bedrock batch inference job.")
    
    inputDataConfig=({
    "s3InputDataConfig": {
        "s3Uri": f"s3://{dest_bucket}/model-input/"
    }
    })

    outputDataConfig=({
    "s3OutputDataConfig": {
        "s3Uri": f"s3://{dest_bucket}/model-output/"
        }
    })
    
    bedrock = boto3.client(service_name="bedrock")
    job_name = f"batch-inference-{datetime.now().strftime('%Y-%m-%d-%H-%M-%S')}"
    try:
        response=bedrock.create_model_invocation_job(
                                                    roleArn="arn:aws:iam::070551638384:role/PassRole-proserve-land-role", # TODO: change the role ARN to the Lambda ARN
                                                    modelId="anthropic.claude-3-5-sonnet-20240620-v1:0",
                                                    jobName=job_name,
                                                    inputDataConfig=inputDataConfig,
                                                    outputDataConfig=outputDataConfig,
                                                    timeoutDurationInHours=72
                                                )
        logging.info(f"Bedrock batch inference job successfully created. Job name: {job_name}")
    except Exception as e:
        logging.error(f"Error creating Bedrock batch inference job: {e}")