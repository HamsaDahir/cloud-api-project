import json
import boto3


s3_client = boto3.client('s3')

def lambda_handler(event, context):
   bucket_name = "my-resume-api"
   key_name = "Resume-json"

   s3_responce = s3_client.get_object(Bucket=bucket_name, Key=key_name)
   print("s3_responce", s3_responce)
   
   
   file_data = s3_responce["Body"].read().decode('utf')
   print("file_data:", file_data)