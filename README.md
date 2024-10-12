# Unlock Gen-AI Powered Insights from Your Amazon RDS (PostgreSQL) Data with Amazon Q Business

## [Overview](#overview)
This CloudFormation template creates a VPC with public and private subnets, a PostgreSQL RDS instance in the private subnet, and a bastion host EC2 instance in the public subnet.

## [Architecture](#architecture)

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

1. An AWS account with sufficient permissions to create the resources
2. AWS CLI installed and configured
3. An existing EC2 Key Pair for SSH access to the bastion host

## [Creating RDS Certificates for SSL Connection](#creating-rds-certificates-for-ssl-connection)

To establish a connection from Amazon Q to the Amazon RDS PostgreSQL instance, you need to have the Amazon RDS certificates in an S3 bucket. Follow these steps to extract the region-specific certificate and upload it to an S3 bucket:

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

## [Cloudformation deployment](#cloudformation-deployment)

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

### [Using the AWS Console](#using-the-aws-console)
1. Log in to the AWS Management Console.
2. Navigate to the CloudFormation service.
3. Click "Create stack" and select "With new resources (standard)".
4. Choose "Upload a template file" and select the CloudFormation script.
5. Fill in the required parameters, such as the database username and key pair name.
6. Review the stack details and create the stack.

### [Using the AWS CLI](#using-the-aws-cli)

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
2. Connect to the bastion host instance using the specified key pair and verify that you can access the RDS instance from the bastion host.
3. Use the RDS endpoint and database credentials (stored in AWS Secrets Manager) to connect to the Postgres database and validate the sample data.

## [Security Considerations](#security-considerations)

- The bastion host security group allows SSH access from any IP (0.0.0.0/0). Consider restricting this to specific IP ranges for improved security.
- Regularly rotate the database credentials and EC2 key pair.

## [Cleanup](#cleanup)

To avoid ongoing charges, delete the CloudFormation stack when you're done using the resources.

1. Delete the CloudFormation stack:
   ```
   aws cloudformation delete-stack --stack-name my-vpc-rds-bastion
   ```

2. Manually delete the database secrets from Secrets Manager (if needed):
   ```
   aws secretsmanager delete-secret --secret-id QBusiness-<<Name of the Secret>> --force-delete-without-recovery
   ```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

