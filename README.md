<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>🚀 Automated Chatbot Deployment with CI/CD on AWS EKS</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      padding: 20px;
    }
    h1, h2, h3 {
      margin-top: 1.5em;
    }
    .emoji {
      font-size: 2rem;
      margin-right: 0.3em;
    }
    ul {
      margin-left: 2em;
    }
    code {
      background: #f4f4f4;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: Consolas, monospace;
    }
    pre {
      background: #f4f4f4;
      padding: 12px;
      border-left: 4px solid #ccc;
      overflow-x: auto;
    }
  </style>
</head>
<body>

<h1><span class="emoji">🚀</span>Automated Chatbot Deployment with CI/CD on AWS EKS</h1>
<p>Welcome to my first end-to-end Continuous Integration and Continuous Delivery (CI/CD) project! 🎉 This repository showcases a robust pipeline designed to automate the build and deployment of a chatbot application onto a Kubernetes cluster running on AWS Elastic Kubernetes Service (EKS).</p>

<h2><span class="emoji">✨</span>Project Overview</h2>
<p>This project was a significant learning milestone, transforming a manual deployment process into a fully automated, efficient, and scalable workflow. It demonstrates practical skills in modern DevOps practices, cloud infrastructure automation, and container orchestration.</p>

<h2><span class="emoji">🛠️</span>Technologies Used</h2>
<ul>
  <li><b>Jenkins:</b> Orchestration engine for the entire CI/CD pipeline ⚙️</li>
  <li><b>AWS EKS:</b> Managed Kubernetes service ☁️</li>
  <li><b>AWS ECR:</b> Docker image repository 📦</li>
  <li><b>Terraform:</b> Infrastructure as Code tool 🏗️</li>
  <li><b>Git:</b> Version control system 🧑‍💻</li>
  <li><b>Docker:</b> Containerization platform 🐳</li>
  <li><b>Kubernetes:</b> Deployment and service YAML files 🌐</li>
</ul>

<h2><span class="emoji">🚦</span>Prerequisites / Requirements</h2>
<ul>
  <li>AWS Account with EKS, ECR, IAM permissions</li>
  <li>Jenkins instance with required plugins (Docker, Kubernetes, AWS)</li>
  <li>Terraform CLI</li>
  <li>Kubectl CLI</li>
  <li>AWS CLI configured</li>
  <li>Docker installed</li>
</ul>

<h2><span class="emoji">🚀</span>Getting Started / Setup Commands</h2>

<h3>1. Clone the Repository</h3>
<pre><code>git clone https://github.com/sharma987piyush/chatbot.git
cd chatbot</code></pre>

<h3>2. Initialize Terraform</h3>
<pre><code># cd path/to/terraform
terraform init</code></pre>

<h3>3. Plan and Apply Terraform</h3>
<pre><code>terraform plan
terraform apply --auto-approve</code></pre>

<h3>4. Configure Kubectl</h3>
<pre><code>aws eks update-kubeconfig --name &lt;your-eks-cluster-name&gt; --region &lt;your-aws-region&gt;</code></pre>

<h3>5. Run Jenkins Pipeline</h3>
<ul>
  <li>Open Jenkins dashboard</li>
  <li>Create new Pipeline job</li>
  <li>Configure SCM to: <code>https://github.com/sharma987piyush/chatbot.git</code></li>
  <li>Ensure <code>Jenkinsfile</code> is in root directory</li>
  <li>Run the job to deploy the chatbot</li>
</ul>

<h2><span class="emoji">🔍</span>Verify Kubernetes Deployment</h2>
<pre><code>kubectl get pods -n &lt;your-namespace&gt;
kubectl get services -n &lt;your-namespace&gt;

# Optional port-forwarding:
kubectl port-forward service/&lt;your-chatbot-service-name&gt; 8080:80</code></pre>

<h2><span class="emoji">🧪</span>CI/CD Pipeline Workflow</h2>
<ul>
  <li><b>Source Code Changes:</b> Triggered by Git commits</li>
  <li><b>Image Build & Push:</b> Jenkins builds Docker image and pushes to ECR</li>
  <li><b>Kubernetes Deployment:</b> Applied using <code>deploy.yml</code> & <code>service.yml</code></li>
  <li><b>Infrastructure Provisioning:</b> Terraform handles AWS infrastructure</li>
</ul>

<h2><span class="emoji">💡</span>Challenges & Key Learnings</h2>
<ul>
  <li>Mastered Jenkins pipelines, Terraform states, Kubernetes manifests</li>
  <li>Integrated Jenkins securely with AWS services</li>
  <li>Improved problem-solving with debugging experience</li>
  <li>Gained confidence in designing robust systems</li>
</ul>

<h2><span class="emoji">🙏</span>Acknowledgements</h2>
<p>Special thanks to <a href="https://www.linkedin.com/in/aviral-meharishi/" target="_blank">Aviral Meharishi</a> for the chatbot app and project support!</p>

<h2><span class="emoji">🌟</span>Future Enhancements</h2>
<ul>
  <li>Add automated testing (unit, integration, e2e)</li>
  <li>Implement blue/green or canary deployments</li>
  <li>Integrate monitoring (Prometheus, Grafana, CloudWatch)</li>
  <li>Adopt GitOps with ArgoCD or Flux</li>
</ul>

<p>🚀 Feel free to explore, contribute, or give feedback!</p>

</body>
</html>
