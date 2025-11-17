pipeline {
    agent any

    environment {
        // SonarQube Configuration
        SONAR_TOKEN = credentials('Sonar')
        SONAR_HOST_URL = 'http://98.94.55.71:9000'
        PROJECT_KEY = 'mern-chat-app'

        // Docker Configuration
        DOCKERHUB_CREDS = credentials('dockerhub-creds')
        IMAGE_NAME = "mernchat-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        
        // Kubernetes Configuration
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        K8S_NAMESPACE = 'prod'
        HELM_RELEASE = 'mern-chatapp-prod'  // ✅ Original name use karo
        HELM_CHART_PATH = '/home/helm/node-app'
    }

    stages {
        
        stage('Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
            }
        }

        stage('Security Scan - Filesystem') {
            steps {
                echo '🔍 Running Trivy filesystem scan (HIGH,CRITICAL)...'
                sh 'trivy fs --severity HIGH,CRITICAL --exit-code 0 . || true'
            }
        }

        stage('SonarQube Code Quality') {
            steps {
                echo '📊 Running SonarQube analysis...'
                script {
                    def scannerHome = tool 'sonar-scanner'
                    
                    sh '''
                        if ! command -v node &> /dev/null; then
                            echo "Node not found, installing..."
                            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                            sudo apt-get install -y nodejs
                        fi
                        echo "Node version: $(node --version || true)"
                    '''

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=${PROJECT_KEY} \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=${SONAR_HOST_URL} \
                              -Dsonar.exclusions=**/node_modules/**,**/dist/**
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo '⏳ Waiting for SonarQube Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:latest
                        echo "✅ Docker image built: ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                    """
                }
            }
        }

        stage('Security Scan - Docker Image') {
            steps {
                echo '🔍 Scanning Docker image with Trivy...'
                script {
                    sh """
                        trivy image --format html --output trivy-report.html \
                          --severity HIGH,CRITICAL \
                          ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG} || true
                    """
                }
            }
        }

        stage('Publish Security Report') {
            steps {
                echo '📄 Publishing Trivy HTML report to Jenkins...'
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'trivy-report.html',
                    reportName: 'Trivy Security Scan Report'
                ])
            }
        }

        stage('Push Docker Image to Registry') {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                script {
                    sh """
                        echo "${DOCKERHUB_CREDS_PSW}" | docker login -u "${DOCKERHUB_CREDS_USR}" --password-stdin
                        docker push ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:latest
                        echo "✅ Image pushed: ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                    """
                }
            }
        }

        stage('Clean Previous Deployment') {
            steps {
                echo '🧹 Cleaning previous deployment if exists...'
                script {
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        export HOME=/var/lib/jenkins
                        
                        # Check if old release exists
                        if helm list -n ${K8S_NAMESPACE} | grep -q ${HELM_RELEASE}; then
                            echo "Found existing release, uninstalling..."
                            helm uninstall ${HELM_RELEASE} -n ${K8S_NAMESPACE} || true
                            sleep 5
                        fi
                        
                        # Clean any leftover resources
                        kubectl delete all -n ${K8S_NAMESPACE} -l "app.kubernetes.io/instance=${HELM_RELEASE}" --ignore-not-found=true
                        kubectl delete sa,configmap,secret -n ${K8S_NAMESPACE} -l "app.kubernetes.io/instance=${HELM_RELEASE}" --ignore-not-found=true
                        kubectl delete hpa -n ${K8S_NAMESPACE} --all --ignore-not-found=true
                        
                        echo "✅ Cleanup completed"
                    """
                }
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                echo '🚀 Deploying to Kubernetes using Helm...'
                script {
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        export HOME=/var/lib/jenkins
                        
                        echo "========================================="
                        echo "Kubernetes Cluster Information"
                        echo "========================================="
                        kubectl cluster-info
                        kubectl get nodes
                        echo ""
                        
                        cd ${HELM_CHART_PATH}
                        
                        echo "========================================="
                        echo "Validating Helm Chart"
                        echo "========================================="
                        helm lint .
                        echo ""
                        
                        helm show chart .
                        echo ""
                        
                        echo "========================================="
                        echo "Deploying Application"
                        echo "========================================="
                        echo "Release: ${HELM_RELEASE}"
                        echo "Namespace: ${K8S_NAMESPACE}"
                        echo "Image: ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                        echo "========================================="
                        
                        helm install ${HELM_RELEASE} . \
                          --namespace ${K8S_NAMESPACE} \
                          --create-namespace \
                          --set image.repository=${DOCKERHUB_CREDS_USR}/${IMAGE_NAME} \
                          --set image.tag=${IMAGE_TAG} \
                          --set image.pullPolicy=Always \
                          --wait \
                          --timeout 10m
                        
                        echo ""
                        echo "========================================="
                        echo "Deployment Created"
                        echo "========================================="
                        kubectl get all -n ${K8S_NAMESPACE}
                        echo ""
                        
                        # Get actual deployment name
                        DEPLOYMENT_NAME=\$(kubectl get deployments -n ${K8S_NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
                        echo "Deployment Name: \$DEPLOYMENT_NAME"
                        echo ""
                        
                        echo "========================================="
                        echo "Waiting for Rollout: \$DEPLOYMENT_NAME"
                        echo "========================================="
                        kubectl rollout status deployment/\$DEPLOYMENT_NAME -n ${K8S_NAMESPACE} --timeout=300s
                        
                        echo ""
                        echo "========================================="
                        echo "✅ Final Status"
                        echo "========================================="
                        kubectl get all -n ${K8S_NAMESPACE}
                        echo ""
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        echo ""
                        
                        echo "========================================="
                        echo "📊 Service Information"
                        echo "========================================="
                        kubectl get svc -n ${K8S_NAMESPACE}
                        
                        # Get NodePort
                        SERVICE_NAME=\$(kubectl get svc -n ${K8S_NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
                        NODE_PORT=\$(kubectl get svc \$SERVICE_NAME -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
                        
                        echo ""
                        echo "========================================="
                        echo "✅ Deployment Completed Successfully!"
                        echo "========================================="
                        echo "📦 Release: ${HELM_RELEASE}"
                        echo "📦 Deployment: \$DEPLOYMENT_NAME"
                        echo "📦 Version: ${IMAGE_TAG}"
                        echo "🌐 NodePort: \$NODE_PORT"
                        echo "🔗 Access URL: http://143.198.122.139:\$NODE_PORT"
                        echo "========================================="
                    """
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up local Docker images...'
            sh """
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG} || true
                docker logout || true
            """
        }
        success {
            echo '✅ ========================================='
            echo '✅ Pipeline Completed Successfully!'
            echo '✅ ========================================='
            echo "✅ Image: ${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
            echo "✅ Deployed to: ${K8S_NAMESPACE} namespace"
            echo "✅ Release: ${HELM_RELEASE}"
            echo '✅ ========================================='
        }
        failure {
            echo '❌ ========================================='
            echo '❌ Pipeline Failed!'
            echo '❌ Please check the logs above for details'
            echo '❌ ========================================='
        }
    }
}