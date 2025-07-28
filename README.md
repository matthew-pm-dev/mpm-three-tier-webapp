This is a demo project to showcase secure and scalable deployment of a classic three tier web app architecture on AWS fronted by a CloudFront distribution using DynamoDB as the storage tier and EC2 AutoScaling Groups for the Web and App tiers.

Project also includes a module testing how to configure a VPC to allow instance management with SSM instead of SSH allowing all web and app tier instances to be kept completely private.

ToDo:
  - Create a more robust test application to verify and demonstrate full connectivity and correct data flow.
  - Host application code in S3 and deploy to Web and App tier instances on creation.
