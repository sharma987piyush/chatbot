pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = '395305481503'  
        AWS_REGION = 'us-east-1'
        ECR_REPO = 'chatbot-docker-repo'
        CLUSTER_NAME = 'chatbot-k8s'
        DOCKER_IMAGE = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/aviralmeharishi/-Are-You-Depressed-AI-Knows-.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-creds') {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    docker push ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                withAWS(credentials: 'aws-creds') {
                    sh """
                    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}
                    kubectl set image deployment/chatbot-deployment chatbot=${DOCKER_IMAGE} --record
                    kubectl rollout status deployment/chatbot-deployment
                    """
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: "SUCCESS: Chatbot deployed successfully! \nImage: ${DOCKER_IMAGE}"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "FAILED: Chatbot deployment failed! \nCheck Jenkins: ${env.BUILD_URL}"
            )
        }
    }
}