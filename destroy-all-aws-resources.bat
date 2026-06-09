@echo off
REM Complete AWS Resource Destruction Script
REM This script destroys ALL resources defined in main.tf in the correct order
REM WARNING: This will delete everything! Use with caution.

setlocal enabledelayedexpansion

set PROJECT_NAME=sample-game-app
set ENVIRONMENT=prod
set AWS_REGION=us-east-1
set NAME_PREFIX=%PROJECT_NAME%-%ENVIRONMENT%

echo.
echo ========================================
echo   COMPLETE AWS RESOURCE DESTRUCTION
echo ========================================
echo.
echo WARNING: This will destroy ALL AWS resources for %NAME_PREFIX%
echo WARNING: This action cannot be undone!
echo.
echo Resources that will be destroyed:
echo - ECS Services and Clusters
echo - Application Load Balancers
echo - RDS Database Instances
echo - ECR Repositories
echo - CloudWatch Log Groups
echo - IAM Roles and Policies
echo - Security Groups
echo - NAT Gateways and Elastic IPs
echo - Subnets and Route Tables
echo - Internet Gateways
echo - VPCs
echo.
echo Press Ctrl+C to cancel, or Enter to continue...
pause

echo.
echo Starting complete AWS resource destruction...
echo.

REM ========================================
REM STEP 1: DELETE ECS SERVICES AND CLUSTERS
REM ========================================
echo [1/12] Deleting ECS Services and Clusters...

REM Delete ECS Services first
for /f "tokens=*" %%i in ('aws ecs list-clusters --region %AWS_REGION% --query "clusterArns[?contains(@, '%NAME_PREFIX%')]" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Processing cluster: %%i
        for /f "tokens=*" %%j in ('aws ecs list-services --cluster %%i --region %AWS_REGION% --query "serviceArns" --output text 2^>nul') do (
            if not "%%j"=="" (
                echo     Deleting service: %%j
                aws ecs update-service --cluster %%i --service %%j --desired-count 0 --region %AWS_REGION% >nul 2>&1
                timeout /t 10 >nul
                aws ecs delete-service --cluster %%i --service %%j --region %AWS_REGION% >nul 2>&1
            )
        )
        timeout /t 5 >nul
        echo   Deleting cluster: %%i
        aws ecs delete-cluster --cluster %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 2: DELETE APPLICATION LOAD BALANCERS
REM ========================================
echo [2/12] Deleting Application Load Balancers...

REM Disable deletion protection first
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --region %AWS_REGION% --query "LoadBalancers[?contains(LoadBalancerName, '%NAME_PREFIX%')].LoadBalancerArn" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Disabling deletion protection for: %%i
        aws elbv2 modify-load-balancer-attributes --load-balancer-arn %%i --attributes Key=deletion_protection.enabled,Value=false --region %AWS_REGION% >nul 2>&1
        timeout /t 5 >nul
        echo   Deleting load balancer: %%i
        aws elbv2 delete-load-balancer --load-balancer-arn %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 3: DELETE TARGET GROUPS
REM ========================================
echo [3/12] Deleting Target Groups...

for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --region %AWS_REGION% --query "TargetGroups[?contains(TargetGroupName, '%NAME_PREFIX%')].TargetGroupArn" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting target group: %%i
        aws elbv2 delete-target-group --target-group-arn %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 4: DELETE RDS INSTANCES
REM ========================================
echo [4/12] Deleting RDS Instances...

REM Disable deletion protection first
for /f "tokens=*" %%i in ('aws rds describe-db-instances --region %AWS_REGION% --query "DBInstances[?contains(DBInstanceIdentifier, '%NAME_PREFIX%')].DBInstanceIdentifier" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Disabling deletion protection for RDS: %%i
        aws rds modify-db-instance --db-instance-identifier %%i --no-deletion-protection --region %AWS_REGION% >nul 2>&1
        timeout /t 10 >nul
        echo   Deleting RDS instance: %%i
        aws rds delete-db-instance --db-instance-identifier %%i --skip-final-snapshot --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 5: DELETE DB SUBNET GROUPS
REM ========================================
echo [5/12] Deleting DB Subnet Groups...

for /f "tokens=*" %%i in ('aws rds describe-db-subnet-groups --region %AWS_REGION% --query "DBSubnetGroups[?contains(DBSubnetGroupName, '%NAME_PREFIX%')].DBSubnetGroupName" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting DB subnet group: %%i
        aws rds delete-db-subnet-group --db-subnet-group-name %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 6: DELETE ECR REPOSITORIES
REM ========================================
echo [6/12] Deleting ECR Repositories...

for /f "tokens=*" %%i in ('aws ecr describe-repositories --region %AWS_REGION% --query "repositories[?contains(repositoryName, '%NAME_PREFIX%')].repositoryName" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting ECR repository: %%i
        aws ecr delete-repository --repository-name %%i --force --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 7: DELETE CLOUDWATCH LOG GROUPS
REM ========================================
echo [7/12] Deleting CloudWatch Log Groups...

for /f "tokens=*" %%i in ('aws logs describe-log-groups --region %AWS_REGION% --query "logGroups[?contains(logGroupName, '%NAME_PREFIX%')].logGroupName" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting log group: %%i
        aws logs delete-log-group --log-group-name %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM Also delete container insights log groups
for /f "tokens=*" %%i in ('aws logs describe-log-groups --region %AWS_REGION% --query "logGroups[?contains(logGroupName, '/aws/ecs/containerinsights')].logGroupName" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting container insights log group: %%i
        aws logs delete-log-group --log-group-name %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 8: DELETE IAM ROLES AND POLICIES
REM ========================================
echo [8/12] Deleting IAM Roles and Policies...

for /f "tokens=*" %%i in ('aws iam list-roles --query "Roles[?contains(RoleName, '%NAME_PREFIX%')].RoleName" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Processing IAM role: %%i
        
        REM Detach attached policies
        for /f "tokens=*" %%j in ('aws iam list-attached-role-policies --role-name %%i --query "AttachedPolicies[].PolicyArn" --output text 2^>nul') do (
            if not "%%j"=="" (
                echo     Detaching policy: %%j
                aws iam detach-role-policy --role-name %%i --policy-arn %%j >nul 2>&1
            )
        )
        
        REM Delete inline policies
        for /f "tokens=*" %%j in ('aws iam list-role-policies --role-name %%i --query "PolicyNames" --output text 2^>nul') do (
            if not "%%j"=="" (
                echo     Deleting inline policy: %%j
                aws iam delete-role-policy --role-name %%i --policy-name %%j >nul 2>&1
            )
        )
        
        echo   Deleting IAM role: %%i
        aws iam delete-role --role-name %%i >nul 2>&1
    )
)

REM Delete custom IAM policies
for /f "tokens=*" %%i in ('aws iam list-policies --scope Local --query "Policies[?contains(PolicyName, '%NAME_PREFIX%')].Arn" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting IAM policy: %%i
        aws iam delete-policy --policy-arn %%i >nul 2>&1
    )
)

REM ========================================
REM STEP 9: DELETE SECURITY GROUPS
REM ========================================
echo [9/12] Deleting Security Groups...

for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --region %AWS_REGION% --query "SecurityGroups[?contains(GroupName, '%NAME_PREFIX%')].GroupId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting security group: %%i
        aws ec2 delete-security-group --group-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 10: DELETE NAT GATEWAYS AND ELASTIC IPs
REM ========================================
echo [10/12] Deleting NAT Gateways and Elastic IPs...

REM Delete NAT Gateways first
for /f "tokens=*" %%i in ('aws ec2 describe-nat-gateways --region %AWS_REGION% --query "NatGateways[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].NatGatewayId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting NAT gateway: %%i
        aws ec2 delete-nat-gateway --nat-gateway-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM Wait for NAT gateways to be deleted
echo   Waiting for NAT gateways to be deleted...
timeout /t 30 >nul

REM Release Elastic IPs
for /f "tokens=*" %%i in ('aws ec2 describe-addresses --region %AWS_REGION% --query "Addresses[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].AllocationId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Releasing elastic IP: %%i
        aws ec2 release-address --allocation-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 11: DELETE SUBNETS AND ROUTE TABLES
REM ========================================
echo [11/12] Deleting Subnets and Route Tables...

REM Delete subnets
for /f "tokens=*" %%i in ('aws ec2 describe-subnets --region %AWS_REGION% --query "Subnets[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].SubnetId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting subnet: %%i
        aws ec2 delete-subnet --subnet-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM Delete route tables (except main)
for /f "tokens=*" %%i in ('aws ec2 describe-route-tables --region %AWS_REGION% --query "RouteTables[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].RouteTableId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting route table: %%i
        aws ec2 delete-route-table --route-table-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM ========================================
REM STEP 12: DELETE INTERNET GATEWAYS AND VPCS
REM ========================================
echo [12/12] Deleting Internet Gateways and VPCs...

REM Detach and delete internet gateways
for /f "tokens=*" %%i in ('aws ec2 describe-internet-gateways --region %AWS_REGION% --query "InternetGateways[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].InternetGatewayId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Processing internet gateway: %%i
        
        REM Get VPC ID for this IGW
        for /f "tokens=*" %%j in ('aws ec2 describe-internet-gateways --internet-gateway-ids %%i --region %AWS_REGION% --query "InternetGateways[0].Attachments[0].VpcId" --output text 2^>nul') do (
            if not "%%j"=="" (
                echo     Detaching from VPC: %%j
                aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id %%j --region %AWS_REGION% >nul 2>&1
            )
        )
        
        echo   Deleting internet gateway: %%i
        aws ec2 delete-internet-gateway --internet-gateway-id %%i --region %AWS_REGION% >nul 2>&1
    )
)

REM Finally delete VPCs
for /f "tokens=*" %%i in ('aws ec2 describe-vpcs --region %AWS_REGION% --query "Vpcs[?contains(Tags[?Key==''Name''].Value, ''%NAME_PREFIX%'')].VpcId" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Deleting VPC: %%i
        aws ec2 delete-vpc --vpc-id %%i --region %AWS_REGION% >nul 2>&1
        if !errorlevel! equ 0 (
            echo     VPC %%i deleted successfully
        ) else (
            echo     Failed to delete VPC %%i - may have remaining dependencies
        )
    )
)

REM ========================================
REM CLEANUP COMPLETED
REM ========================================
echo.
echo ========================================
echo   DESTRUCTION COMPLETED!
echo ========================================
echo.
echo All AWS resources for %NAME_PREFIX% have been destroyed.
echo.
echo Please verify in AWS Console that all resources are removed.
echo.
echo Press any key to exit...
pause >nul
