# Unlock Gen-AI Powered Insights from Your Amazon RDS (PostgreSQL) Data with Amazon Q Business

## [Overview](#overview)
This CloudFormation template sets up the infrastructure required to enable Amazon Q Business to connect to and analyze data from an Amazon RDS (PostgreSQL) database. Specifically, the template performs the following tasks:

1. Creates a VPC with public and private subnets to host the resources.
2. Deploys a PostgreSQL RDS instance in a private subnet, ensuring it is not publicly accessible.
3. Provisions a bastion host EC2 instance in the public subnet, which can be used to securely access the RDS instance.
4. Generates a Secrets Manager secret to store the database credentials, ensuring they are protected and can be easily retrieved.
5. Initializes the PostgreSQL database with sample/test data, including tables for sustainability projects, sustainability scores, and stakeholders.

The goal of this infrastructure is to provide a secure and ready-to-use environment for users to connect Amazon Q Business to the RDS PostgreSQL database and unlock valuable insights from the sample sustainability data. By automating the provisioning of these resources, users can quickly set up the necessary foundation to explore the capabilities of Amazon Q Business.

## [About test data](#abouttestdata)

The test data represents a sustainability management system that tracks various sustainability projects, their scores, and the stakeholders involved. Richard Roe, the Secrets Projects Custodian, has access only to the "Secret Sustainability Project" (project_id 6), while Alejandro Rosalez, the General Projects Custodian, has access to all the general sustainability projects (project_id 1-5) but not the secret project. The data shows that there are 6 sustainability projects in total, allowing example.org to manage and monitor their sustainability initiatives while maintaining the confidentiality of the sensitive project based on the different access levels for Richard and Alejandro.

The SQL statements to create the tables and insert the test data are provided in the [test-data.sql](test-data.sql) file. You can review the contents of this file to familiarize yourself with the test data schema and sample records.

## [Template creates following AWS resources](#resources-created)

The template sets up the following components:

1. VPC with CIDR 10.0.0.0/16
2. Public subnet (10.0.1.0/24) in the first Availability Zone
3. Two private subnets (10.0.2.0/24 and 10.0.3.0/24) in different Availability Zones
4. Internet Gateway for public internet access
5. NAT Gateway for private subnet internet access
6. Route tables for public and private subnets
7. PostgreSQL RDS instance in the private subnet
8. Bastion host EC2 instance in the public subnet
9. Security groups for RDS and bastion host
10. IAM role and instance profile for the bastion host
11. Secrets Manager secret for storing database credentials

## [Prerequisites](#prerequisites)

Before deploying this template, ensure you have:

1. An AWS account with sufficient permissions to create the above listed resources
2. AWS CLI installed and configured (Optional, if you are using the AWS Session manager to connect to EC2 Instance)
3. An existing EC2 Key Pair for SSH access to the bastion host

## [Security Considerations](#security-considerations)

- The bastion host security group allows SSH access from any IP (0.0.0.0/0). Consider restricting this to specific IP ranges for improved security.
- Regularly rotate the database credentials and EC2 key pair.

## [Clone the Repository](#clone-the-repository)

1. Clone the repository:
   ```
   git clone https://github.com/aws-samples/Unlock-GenAI-Powered-Insights-from-Your-Amazon-RDS-PostGreSQL-Data-with-Amazon-Q-Business.git
   ```
2. Change into the project directory:
   ```
   cd Unlock-GenAI-Powered-Insights-from-Your-Amazon-RDS-PostGreSQL-Data-with-Amazon-Q-Business
   ```

## [Parameters](#parameters)

- `DatabaseUsername`: The username for the RDS database (must begin with a letter and contain only alphanumeric characters)
- `KeyPairName`: Name of an existing EC2 KeyPair to enable SSH access to the bastion host

## [Deployment](#deployment)

### [Option1: Using the AWS Console](#using-the-aws-console)
1. Log in to the AWS Management Console.
2. Navigate to the CloudFormation service.
3. Click "Create stack" and select "With new resources (standard)".
4. Choose "Upload a template file" and select the CloudFormation script(rds-postgresql-main-template.yaml).
5. Fill in the required parameters, such as the database username and key pair name.
6. Review the stack details and create the stack.

### [Option2: Using the AWS CLI](#using-the-aws-cli)

To deploy this CloudFormation stack:
1. Save the template to a file (e.g., `rds-postgresql-main-template`)
2. Run the following AWS CLI command:

```bash
aws cloudformation create-stack \
  --stack-name my-vpc-rds-bastion \
  --template-body file://rds-postgresql-main-template.yaml \
  --parameters ParameterKey=DatabaseUsername,ParameterValue=mydbuser \
               ParameterKey=KeyPairName,ParameterValue=my-keypair \
  --capabilities CAPABILITY_IAM
```

Replace `my-vpc-rds-bastion`, `mydbuser`, and `my-keypair` with your desired values.

## [Outputs](#outputs)

The template provides the following outputs:

- VPC ID
- Public Subnet ID
- Private Subnet 1 ID
- Private Subnet 2 ID
- RDS Database Endpoint
- Bastion Host Instance ID
- Database Credentials Secret ARN

## [Validation](#validation)

To verify the deployment, you can do the following:

1. Check the CloudFormation stack status in the AWS Management Console or by running `aws cloudformation describe-stacks --stack-name my-vpc-rds-bastion`.
2. Connect to the bastion host instance using the specified key pair or through session manager, and verify the file under /tmp/user-data-* to confirm the status of the table setup
3. Use the RDS endpoint and database credentials (stored in AWS Secrets Manager) to connect to the Postgres database and validate the sample data.

```bash
psql \
   --host=RDSENDPOINT \
   --port=5432 \
   --username=DBUSER \
   --password \
   --dbname=postgres \
   --set=sslmode=require

# Execute the following SQL commands to display the contents of the tables
SELECT * FROM sustainability_projects; 
SELECT * FROM sustainability_scores;
SELECT * FROM stakeholders;
```

## [Creating RDS Certificates for SSL Connection](#creating-rds-certificates-for-ssl-connection)

To establish a connection from Amazon Q to the Amazon RDS PostgreSQL instance, you need to have the Amazon RDS certificates in an S3 bucket. 
Note: The following commands can be executed on the Bastion EC2 host, [AWS CloudShell](https://aws.amazon.com/cloudshell/), or on your local machine, depending on your preference and setup.
Follow these steps to extract the region-specific certificate and upload it to an S3 bucket:

1. Create an S3 bucket to store the SSL certificates:
   ```
   BUCKET_NAME="my-rds-ssl-certificates-$(date +%s)"
   aws s3 mb s3://$BUCKET_NAME
   ```

2. Download the global bundle of SSL/TLS certificates from Amazon RDS:
   ```
   wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
   ```
3. Convert the certificate bundle from CRL format to PEM format:
   ```
   openssl crl2pkcs7 -nocrl -certfile global-bundle.pem | openssl pkcs7 -print_certs -out all-certs.pem
   ```
<span style="background-color: grey; font-weight: bold;">The region in the grep command below should be the region where the RDS resides.</span>

4. Extract the RDS Root CA certificate (RSA 2048-bit, G1) from the certificate bundle:
   ```
   grep -A 25 "CN=Amazon RDS us-east-1 Root CA RSA2048 G1" all-certs.pem | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > rds-ca-rsa2048-g1.pem
   ```

5. Upload the `rds-ca-rsa2048-g1.pem` file to an S3 bucket and note down the path. AWS CLI command aws s3 cp rds-ca-rsa2048-g1.pem s3://$BUCKET_NAME/



## [Cleanup](#cleanup)

To avoid ongoing charges, delete the CloudFormation stack when you're done using the resources.

1. Remove the `AmazonS3ReadOnlyAccess` policy from the IAM role created by the CloudFormation stack:
   - Navigate to the IAM service in the AWS Management Console.
   - Locate the IAM role with a name starting with `QBusiness-DataSource-`.
   - Remove the `AmazonS3ReadOnlyAccess` managed policy from the role.

2. Delete the CloudFormation stack:
   Option1: From AWS Console
   - Go to the CloudFormation service in the AWS Management Console.
   - Find the stack you created (e.g., "my-vpc-rds-bastion").
   - Select the stack and click "Delete".
   
   Option2: Using AWS CLI
   ```
   aws cloudformation delete-stack --stack-name my-vpc-rds-bastion
   ```

3. Manually delete the database secrets from Secrets Manager:
   Option1: From AWS Console
   - Navigate to the Secrets Manager service in the AWS Management Console.
   - Locate the secret with a name starting with "QBusiness-".
   - Click on the secret and select "Delete secret" and shedule for deletion. 
   - Secrets Manager requires a minimum waiting period of 7 days before deleting a secret. You will not be able to retrieve the secret once it is scheduled for deletion.

   Option2: AWS CLI to delete immeditely
   ```
   aws secretsmanager delete-secret --secret-id QBusiness-<<Name of the Secret>> --force-delete-without-recovery
   ```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
