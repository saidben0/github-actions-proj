import json
import boto3
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.resource('ec2')
rds_client = boto3.client('rds')
elbv2_client = boto3.client('elbv2')
elb_client = boto3.client('elb')

def lambda_handler(event, context):
    try: 
        logger.info("Received EVENT:")
        logger.info(json.dumps(event))
        eventname = event['detail']['eventName']
        detail = event['detail']
        principal = detail['userIdentity']['principalId']
        userType = detail['userIdentity']['type']
        if userType == 'IAMUser':
            user = detail['userIdentity']['userName']
        else:
            user = principal.split(':')[1]
        #add more tags to the below list if required
        tags = [
            {'Key': 'automated', 'Value': 'false'},
            {'Key': 'team', 'Value': 'devops'},
            {'Key': 'paging', 'Value': 'none'},
            {'Key': 'owner', 'Value': user}
        ]
        logger.info(f"Received AWS API event name is {eventname}")

        if eventname == "RunInstances":
            ec2_instance_ids_list = get_ec2_instances(detail)
            if len(ec2_instance_ids_list) > 0:
                tag_ec2_resources([ec2_instance_ids_list], tags)
            logger.info(ec2_instance_ids_list)
            
        if eventname == "CreateVolume":
            ebs_volume_id = get_ebs_volumes(detail)
            if len(ebs_volume_id) > 0:
                tag_ec2_resources([ebs_volume_id], tags)
            logger.info(ebs_volume_id)

        if eventname == "CreateDBInstance":
            rds_id_to_tag = check_rds_tags(event['detail']['responseElements']['dBInstanceArn'])
            if len(rds_id_to_tag) > 0:
                tag_rds_resource(rds_id_to_tag, tags)
            logger.info(rds_id_to_tag)

        if eventname == "CreateDBCluster":
            rds_id_to_tag = check_rds_tags(event['detail']['responseElements']['dBClusterArn'])
            if len(rds_id_to_tag) > 0:
                tag_rds_resource(rds_id_to_tag, tags)
            logger.info(rds_id_to_tag)
   
        if eventname == "CreateLoadBalancer":
            elbs_to_tag = check_elb_tags(event['detail'])
            logger.info(elbs_to_tag)
            if elbs_to_tag:
                if elbs_to_tag['ELB_Type'] == 'Classic':
                    tag_elb(elbs_to_tag['ELB_Name'], tags)
                else:
                    tag_elbv2(elbs_to_tag['ELB_Arn'], tags)

        if eventname == "CreateTargetGroup":
            tg_to_tag = check_target_group_tags(event['detail'])
            logger.info(tg_to_tag)
            if tg_to_tag:
                tag_elbv2(tg_to_tag['TG_Arn'], tags)

    except ClientError as error:
        logger.info({"errorcode": error.response['Error']['Code'],
                     "errormessage" : error.response['Error']['Message'] })
        raise
    except Exception as e:
        logger.info({"errorcode": "Something went wrong. Try later or contact the admin", 
                     "errormessage": str(e) })
        raise
    return {"success": "Code ran successfully. "}

def get_ec2_instances(detail):
    logger.info(detail)
    ids = []
    items = detail['responseElements']['instancesSet']['items']
    for item in items:
        ids.append(item['instanceId'])
    logger.info('number of instances: ' + str(len(ids)))

    base = ec2.instances.filter(InstanceIds=ids)
    # loop through the instances
    instance_tag_exists = False
    for instance in base:
        if instance.tags:
            for tag in instance.tags:
                if tag['Key'] == 'automated' and tag['Value'] == 'true':
                    tag_underlying_resource_automated_true(instance)
                    ids.remove(instance.id)
                    instance_tag_exists = True
                    break

        for vol in instance.volumes.all():
            logger.info("check volume tags")
            if not instance_tag_exists:
                ids.append(vol.id)

        for eni in instance.network_interfaces:
            logger.info("check eni tags")
            if not instance_tag_exists:
                ids.append(eni.id)
    
        instance_tag_exists = False
    return ids

def tag_ec2_resources(resourcelist, tags):
    logger.info(f"Recevied list of resources for tagging: {resourcelist}")
    for resourceid in resourcelist:
        logger.info('Tagging resource ' + str(resourceid))
        ec2.create_tags(Resources=resourceid, Tags=tags)


def get_ebs_volumes(detail):
    logger.info(detail)
    volumeId = detail['responseElements']['volumeId']
    id = [volumeId]
    describevolumes = ec2.volumes.filter(VolumeIds=[
        volumeId
    ])
    for volume in describevolumes:
        if volume.tags:
            for tag in volume.tags:
                if (tag['Key'] == 'automated' and tag['Value'] == 'true'):
                    id.remove(volumeId)
                    break
    return id

def check_rds_tags(rds_arn):
    id =[rds_arn]
    tags = rds_client.list_tags_for_resource(
        ResourceName=rds_arn
    )['TagList']
    if len(tags) > 0:
        for tag in tags:
            if (tag['Key'] == 'automated' and tag['Value'] == 'true'):
                id.remove(rds_arn)
                break
    return id
                
def tag_rds_resource(resource_ids, tags):
    for id in resource_ids:
        logger.info('Tagging resource ' + str(id))
        rds_client.add_tags_to_resource(
        ResourceName=id,
        Tags=tags
        )
        
def tag_underlying_resource_automated_true(instance_details):
    logger.info("syncing tags from EC2 instance to EBS volumes and ENIs attached to it for instances created by automation")
    resource_list = []
    instance_tag_list_all = instance_details.tags
    instance_tag_list = instance_tag_list_all.copy()
    for i in instance_tag_list_all:
        if i['Key'].startswith('aws:'):
            logger.info(f"removing the tag keys that start with AWS reserved keyword 'aws' for tagging EBS volumes and ENIs: {i}")
            instance_tag_list.remove(i)
    volume_details = instance_details.volumes.all()
    for vol in volume_details:
        resource_list.append(vol.id)
    eni_details = instance_details.network_interfaces
    for eni in eni_details:
        resource_list.append(eni.id)
    tag_ec2_resources([resource_list], instance_tag_list)

def check_elb_tags(detail):
    #check if Classic or Application/Network
    if detail['requestParameters']['type']:
        logger.info("This is not classic loadbalancer")
        classic = False
    else:
        classic = True

    if classic:
        elb_name = detail['requestParameters']['loadBalancerName']
        if 'tags' in detail['requestParameters']:
            elb_creation_tags = detail['requestParameters']['tags']
            for tag in elb_creation_tags:
                if tag['key'] == 'automated' and tag['value'] == 'true':
                    return {}
                else:
                    continue
        return {"ELB_Type": "Classic", "ELB_Name": elb_name}
    else:
        elb_arn = detail['responseElements']['loadBalancers'][0]['loadBalancerArn']
        if 'tags' in detail['requestParameters']:
            elb_creation_tags = detail['requestParameters']['tags']
            for tag in elb_creation_tags:
                if tag['key'] == 'automated' and tag['value'] == 'true':
                    return {}
                else: 
                    continue
        return {"ELB_Type": "App/Net", "ELB_Arn": elb_arn}

def tag_elb(elb_name, tags):
    logger.info(f"tagging classic loadbalancer: {elb_name}")
    elb_client.add_tags(
    LoadBalancerNames=[
        elb_name,
    ],
    Tags=tags
    )

def tag_elbv2(resource_arn,tags):
    logger.info(f"tagging application/network loadbalancer or target group: {resource_arn}")
    elbv2_client.add_tags(
    ResourceArns=[
        resource_arn,
    ],
    Tags=tags
    )

def check_target_group_tags(detail):
    target_group_arn = detail['responseElements']['targetGroups'][0]['targetGroupArn']
    logger.info(f"Tagging the target group: {target_group_arn}")
    all_tags = elbv2_client.describe_tags(
    ResourceArns=[
        target_group_arn,
    ]
    )['TagDescriptions'][0]['Tags']
    for tag in all_tags:
        if tag['Key'] == 'automated' and tag['Value'] == 'true':
            return {}
        else: 
            continue
    return {"TG_Arn": target_group_arn}
