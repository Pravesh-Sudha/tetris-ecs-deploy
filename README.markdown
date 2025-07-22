# Tetris ECS Deployment

This project deploys a web-based Tetris game on AWS ECS (Elastic Container Service) using Fargate. The application runs in a Docker container (`uzyexe/tetris:latest`) and is accessible via a public IP address. The infrastructure is provisioned using Terraform, leveraging the default VPC and subnets, with a custom security group for HTTP access and CloudWatch for logging.

## Prerequisites

- **AWS Account**: Configured with sufficient permissions for ECS, EC2, IAM, and CloudWatch.
- **Terraform**: Installed (version >= 1.0).
- **AWS CLI**: Installed and configured with credentials (`aws configure`).
- **Git**: To clone the repository.

## Repository Structure

```
tetris-ecs-deploy/
├── main.tf           # Terraform configuration for ECS & IAM
└── README.md         # Project documentation
├── backend.tf        # Remote Backend on S3 bucket
└── provider.tf       # Provider Configuration
├── values.tf         # Default Values of vpc, subnet & new Sg
└── get_ip.sh         # Script to get the Public IP of task
```

## Demo Image

![alt text](game.png)

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Pravesh-Sudha/tetris-ecs-deploy.git
   cd tetris-ecs-deploy
   ```

2. **Install Terraform**:
   - Follow the [official Terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).
   - Verify with:
     ```bash
     terraform version
     ```

3. **Configure AWS CLI**:
   - Run `aws configure` to set your AWS Access Key, Secret Key, and region (e.g., `us-east-1`).
   - Ensure the region matches the one in `main.tf` (`us-east-1` by default).

## Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the Deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```
   - Type `yes` to confirm.

4. **Retrieve the Public IP**:
   After deployment, use the following AWS CLI commands to get the public IP of the ECS task:
   ```bash
   # List running tasks
   aws ecs list-tasks --cluster tetris-cluster --service-name tetris-service --region us-east-1

   # Describe task to get network interface ID (replace <task-arn> with the ARN from the previous command)
   aws ecs describe-tasks --cluster tetris-cluster --tasks <task-arn> --region us-east-1

   # Get public IP (replace <eni-id> with the networkInterfaceId from the previous command)
   aws ec2 describe-network-interfaces --network-interface-ids <eni-id> --region us-east-1 --query 'NetworkInterfaces[0].Association.PublicIp' --output text
   ```

   Example output:
   ```
   54.123.45.67
   ```

5. **Access the Tetris Game**:
   - Open `http://<public-ip>:80` in a browser to play the Tetris game.

6. **Clean Up**:
   To avoid AWS charges, destroy the resources:
   ```bash
   terraform destroy
   ```
   - Type `yes` to confirm.

## Optional: Automated Script to Get Public IP

To simplify retrieving the public IP, use this bash script:

```bash
#!/bin/bash
REGION="us-east-1"
CLUSTER="tetris-cluster"
SERVICE="tetris-service"

TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --region $REGION --query 'taskArns[0]' --output text)
if [ -z "$TASK_ARN" ]; then
  echo "No running tasks found in service $SERVICE"
  exit 1
fi

ENI_ID=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
if [ -z "$ENI_ID" ]; then
  echo "No network interface found for task $TASK_ARN"
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
if [ -z "$PUBLIC_IP" ]; then
  echo "No public IP assigned to task"
  exit 1
fi

echo "Public IP: $PUBLIC_IP"
echo "Access Tetris at: http://$PUBLIC_IP:80"
```

- Save as `get-ecs-public-ip.sh`, make executable (`chmod +x get-ecs-public-ip.sh`), and run:
  ```bash
  ./get-ecs-public-ip.sh
  ```

## Notes

- **Public IP Stability**: The task’s public IP may change if the task restarts. For a stable endpoint, consider adding an Application Load Balancer (ALB).
- **Security**: The security group allows HTTP traffic (port 80) from `0.0.0.0/0`. For production, restrict `cidr_blocks` to specific IPs in `main.tf`.
- **Default VPC/Subnets**: Ensure your default VPC has public subnets with an Internet Gateway and routes to `0.0.0.0/0`. Check in the AWS Console (VPC > Subnets) if the IP is unreachable.
- **Image**: Uses `uzyexe/tetris:latest`, assumed to serve a web-based Tetris game on port 80.
- **Logging**: Container logs are stored in CloudWatch at `/ecs/tetris-task`.

## Debugging

If the application is inaccessible:
- **ECS Service Events**: Check ECS > Clusters > `tetris-cluster` > `tetris-service` > Events tab.
- **CloudWatch Logs**: View logs in CloudWatch > Log Groups > `/ecs/tetris-task`.
- **Subnet Verification**: Confirm default subnets are public in the AWS Console (VPC > Subnets > Route Table with `0.0.0.0/0` to an Internet Gateway).
- **Test Connectivity**: Run `curl http://<public-ip>:80` to verify the application.

## Author

- **Pravesh Sudha**
  - LinkedIn: [pravesh-sudha](https://www.linkedin.com/in/pravesh-sudha/)
  - Twitter/X: [@praveshstwt](https://x.com/praveshstwt)
  - YouTube: [@pravesh-sudha](https://www.youtube.com/@pravesh-sudha)

## License

This project is licensed under the MIT License.