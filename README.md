# WhatsApp Chat Bot 🤖💬

This repository contains the infrastructure and workflow files required to instal n8n self-hosted on aws and run WhatsApp assistant in a production. The main goal is to provide a practical and deployable template for a WhatsApp automation bot powered by n8n and OpenAI, including core production setup elements: custom domain, HTTPS/TLS, reverse proxy, and persistent database storage.

## Project Structure 🗂️

- `aws/`
  - `template.yaml`: Cloudformation template to create AWS Lightsail instance, static IP definition and execute boostrap script.
  - `bootstrap.sh`: Server bootstrap script to install and set up Docker, Docker Compose, Nginx, and Certbot.
- `docker/`
  - `.env`: Environment variables for domain and PostgreSQL credentials.
  - `docker-compose.yml`: Create and deploy n8n + PostgreSQL containers services with persistent volumes.
- `n8n/`
  - `whatsapp-chatbot.json`: n8n workflow.
- `nginx/`
  - `reverse-proxy.conf`: Reverse proxy from port 80 to local n8n service (`127.0.0.1:5678`).

## Deployment 🚀

The installation is automated using a CloudFormation template that creates:

- AWS Lightsail instance  
- Network and communication permissions  
- Static public IP address  
- Startup script to install docker, n8n, database (postgres), web server (nginx), and certbot  

### Template Parameters:

- InstanceName: instance name  
- BlueprintId: base image, for example `amazon_linux_2023`  
- BundleId: instance size  
- AvailabilityZone: AWS region and zone  
- StaticIPName: static IP name  
- DBUser: database user  
- DBPassword: database password  
- Domain: public domain for n8n  
- Email: email for HTTPS certificate  

You can run the CloudFormation template using AWS CLI or AWS Console.

### Option A: Deploy from Command Line 💻

1. Configure access keys to connect AWS CLI with your AWS account  

2. Go to the path where you downloaded the `whatsapp-chatbot` project, inside the `aws` folder  

3. Run this command. Replace `Domain` and `Email` with your values:

```bash
aws cloudformation deploy \
    --stack-name n8n \
    --template-file template.yaml \
    --region us-east-1 \
    --parameter-overrides \
        InstanceName=n8n-instance \
        AvailabilityZone=us-east-1a \
        BlueprintId=amazon_linux_2023 \
        BundleId=small_3_0 \
        Domain={Domain} \
        DBUser=admin \
        DBPassword=admin \
        Email={email} \
        StaticIpName=n8n-ip-address
```

### Option B: Deploy from AWS Console 🌐

1. Log in to AWS Console  

2. Go to CloudFormation and create a new stack  

3. Import the template (`template.yaml`) and follow the steps to set parameters like `Domain` and `Email` 

## Set up 🛠️

Please follow this [dev.to post](https://dev.to/joseluissr/how-to-build-a-whatsapp-chatbot-with-n8n-aws-and-openai-feh) to set up the credentials necessary to import n8n workflow, and connect to OpenAI API and META API. 

## Workflow process 🏗️

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jba3f29mgjnz7w4qwnbw.png)

The workflow actions and point decisions are:

1. A user message arrives through the n8n WhatsApp trigger.
2. The workflow checks whether the message contains audio or plain text.
3. If audio:
  - Media is downloaded from WhatsApp.
  - Audio is transcribed with OpenAI.
4. The final message text (original text or transcription) is sent to the AI Agent node.
5. The generated response is sent back to the same user through WhatsApp API.