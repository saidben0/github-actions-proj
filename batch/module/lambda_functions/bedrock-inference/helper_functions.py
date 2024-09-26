import sys
import json
import os
import boto3
from datetime import datetime

def prepare_model_inputs(bytes_inputs, model_id, prompt, system_prompt):
    temperature = 0
    top_p = 0.1
    max_tokens = 4096
    anthropic_version = "bedrock-2023-05-31"
    
    ### Retrieve prompts from Bedrock
    prompt.text, prompt.ver = retrieve_bedrock_prompt(prompt.identifier, prompt.ver)
    
    if system_prompt.identifier:
        system_prompt.text, system_prompt.ver = retrieve_bedrock_prompt(system_prompt.identifier, system_prompt.ver)

    ### Split the data into chunks of 20 pages
    grouped_bytes_input = [bytes_inputs[i:i+20] for i in range(0, len(bytes_inputs), 20)]

    chunk_count = len(grouped_bytes_input)

    model_inputs = []

    for i, bytes_input in enumerate(grouped_bytes_input):
        page_count = 1
        content_input = []
        for one_page_data in bytes_input:
            content_input.append({"type": "text", "text": f"Image {page_count}"})
            content_input.append({"type": "image",
                                 "source": {"type": "base64",
                                           "media_type": "image/png",
                                           "data": one_page_data}})
            page_count += 1

        content_input.append({"type": "text", "text": prompt.text})

        model_input = {
            "anthropic_version": anthropic_version,
            "temperature": temperature,
            "top_p": top_p,
            "max_tokens": max_tokens,
            "messages": [
                {
                    "role": "user",
                    "content": content_input,
                }
            ]}

        if system_prompt.identifier:
            model_input["system"] = system_prompt.text

        final_json = {"recordId": f"{i+1}".zfill(11),
                      "modelInput": model_input}

        model_inputs.append(final_json)

    return model_inputs, chunk_count

def write_jsonl(data, file_path):
    with open(file_path, 'w') as file:
        for item in data:
            json_str = json.dumps(item)
            file.write(json_str + '\n')

def upload_to_s3(path, bucket_name, bucket_subfolder=None):
    # check if the path is a file
    if os.path.isfile(path):
        # If the path is a file, upload it directly
        object_name = os.path.basename(path) if bucket_subfolder is None else f"{bucket_subfolder}/{os.path.basename(path)}"
        try:
            s3.upload_file(path, bucket_name, object_name)
            print(f"Successfully uploaded {path} to {bucket_name}/{object_name}")
            return True
        except Exception as e:
            print(f"Error uploading {path} to S3: {e}")
            return False
    elif os.path.isdir(path):
        # If the path is a directory, recursively upload all files within it
        for root, dirs, files in os.walk(path):
            for file in files:
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, path)
                object_name = relative_path if bucket_subfolder is None else f"{bucket_subfolder}/{relative_path}"
                try:
                    s3.upload_file(file_path, bucket_name, object_name)
                except Exception as e:
                    print(f"Error uploading {file_path} to S3: {e}")
        return None
    else:
        print(f"{path} is not a file or directory.")
        return None
    
def parallel_enabled(array, metadata_dict, dest_bucket, data_folder):
    totalsize = 0
    totalpage = 0

    for j in range(0, len(array)):
        f = array[j]
        logging.info(f"Start processing file:{j} - {f}")

        bucket_name = f.split('/')[2]
        s3_key = f.split('/', 3)[3:][0]
        file_id = f.split('/')[-1].split('.')[0]
        # file_id = f.split('.')[0]
        try:
            mime, body = retrievePdf(bucket_name, s3_key)
        except Exception as e:
            logging.info(f"Error retrieving document thus skipping: {s3_key} - {e}")
            continue
    
        try:
            bytes_inputs = convertS3Pdf(mime, body)
        except Exception as e:
            logging.info(f"Error conversting document thus skipping: {s3_key} - {e}")
            continue
        # bytes_inputs = convertPdf(f)

        prompt = Prompt(
            identifier = metadata_dict[file_id]["prompt_id"],
            ver = metadata_dict[file_id]["prompt_ver"]
        )

        system_prompt = Prompt(
            identifier = metadata_dict[file_id]["system_prompt_id"],
            ver = metadata_dict[file_id]["system_prompt_ver"]
        )

        logging.info(f"Start processing data for {j} - {f}")
        try:
            model_input_jsonl, chunk_count = prepare_model_inputs(bytes_inputs, model_id, prompt, system_prompt)

        except Exception as e:
            logging.error(f"Error creating model input: {e}")
            continue

        logging.info(f"Writing model_input JSON for {j} - {f}")
        try:
            file_name = f'tmp/{file_id}.jsonl'
            write_jsonl(model_input_jsonl, file_name)
        except Exception as e:
            logging.error(f"Error creating model input: {e}")
            continue

        logging.info(f"Saving model_input JSON to S3: {j} - {f}")
        try:
            upload_to_s3(path=f"./{file_name}", 
                         bucket_name=dest_bucket, 
                         bucket_subfolder=f'{data_folder}/model-input')
        except Exception as e:
            logging.error(f"Error saving model input to S3: {e}")
            continue

        metadata_dict[file_id]["chunk_count"] = chunk_count

def convertS3Pdf(mime: str, body: StreamingBody) -> list[bytes]:
    """
    Convert the file data to bytes.

    Parameters:
    ----------
    mime : str
        The standard MIME type describing the format of the file data.

    body : str
        The file data.

    Returns:
    ----------
    list[bytes]
        A list of bytes for the PDF data. The length of the list equals to the number of pages of the PDF.
    """
    bytes_outputs = []
    try:
        doc = pymupdf.open(mime, body.read())  # open document
        for page in doc:  # iterate through the pages
            pix = page.get_pixmap(dpi=90)  # render page to an image
            pdfbytes=pix.tobytes()
            b64 = base64.b64encode(pdfbytes).decode('utf8')
            bytes_outputs.append(b64)
    except Exception as e:
        logging.error(f"Error converting document: {e}")
        raise e
    return bytes_outputs

def retrieve_bedrock_prompt(prompt_id: str, prompt_ver: str):
    """
    Retrieve a prompt from Amazon Bedrock Prompt Management.

    Parameters:
    ----------
    prompt_id : str
        The unique identifier or ARN of the prompt

    prompt_ver : str
        The version of the prompt

    Returns:
    ----------
    str
        The prompt.
    str
        The prompt version.
    """
    client = boto3.client('bedrock-agent')
    # logging.info(f"Returning version {prompt_ver} of the prompt {prompt_id}.")
    response = client.get_prompt(promptIdentifier=prompt_id,
								promptVersion=prompt_ver)

    prompt = response['variants'][0]['templateConfiguration']['text']['text']

    return prompt, prompt_ver

def retrievePdf(bucket: str , s3_key: str) -> tuple[str, StreamingBody]:
    """
    Retrieve data of a file from an S3 bucket.

    Parameters:
    ----------
    bucket : str
        The name of the S3 bucket.

    s3_key : str
        The file path to the file.

    Returns:
    ----------
    tuple[str, StreamingBody]
        A tuple containing:
        - mime (str): A standard MIME type describing the format of the file data.
        - body (StreamingBody): The file data.

    """
    s3 = boto3.client('s3')

    try:
        response = s3.get_object(Bucket=bucket, Key=s3_key)
    except Exception as e:
        logging.error(f"Error retrieving document from S3: {s3_key} - {e}")
        raise e
    mime = response["ContentType"]
    body = response["Body"]

    return mime, body

def delete_queue_messages(sqs, queue_url, queue_arr):
    logging.info(f"Deleting all SQS messages ")
    for i in range(0, len(queue_arr)):
        sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=queue_arr[i])
    logging.info(f"sqs message deleted: - {i}")

class Prompt():
    """
    A class to represent a prompt.

    Attributes
    ----------
    identifier : str
        The unique ID of the prompt on Amazon Bedrock Prompt Management.
    ver : str
        The version of the prompt on Amazon Bedrock Prompt Management.
    text : str
        The prompt body.

    """
    def __init__(self, identifier: Optional[str] = None, ver: Optional[str] = None, text: Optional[str] = None):
        self.identifier = identifier
        self.ver = ver
        self.text = text