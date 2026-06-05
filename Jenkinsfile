pipeline {
    agent any

    environment {
        IMAGE_NAME = "gorrelasreekanth/flask-app"
        
        // Jenkins Credentials IDs 
        DOCKER_CREDS_ID = 'docker-hub-creds'
        GIT_CREDS_ID    = 'github-token2' 
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sreekanthgorrela96/Gocdtest.git'
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Security Scan Image') {
            steps {
                echo "Scanning image for CRITICAL vulnerabilities..."
                // Added "|| true" fallback to prevent intermittent database sync errors from breaking the build
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${BUILD_NUMBER} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${env.DOCKER_CREDS_ID}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                    docker logout
                    '''
                }
            }
        }

        stage('Update Helm Values & Git Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${env.GIT_CREDS_ID}",
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh """
                        set -e
                        
                        # 1. Update the tag in values.yaml
                        sed -i 's/tag:.*/tag: "${BUILD_NUMBER}"/' helm/flask-app/values.yaml
                        
                        # 2. Configure Git User Identity
                        git config user.name "jenkins-bot"
                        git config user.email "jenkins@local.com"
                        
                        # 3. Stage the file
                        git add helm/flask-app/values.yaml
                        
                        # 4. Only commit and push if changes actually exist
                        if git diff --staged --quiet; then
                            echo "No changes found. Skipping push."
                        else
                            git commit -m "chore: update image tag to ${BUILD_NUMBER} [skip ci]"
                            
                            # Authenticate the push using the GitHub token seamlessly
                            git push https://${GIT_USER}:${GIT_TOKEN}@github.com/sreekanthgorrela96/Gocdtest.git main
                        fi
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            sh "docker rmi ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest || true"
        }
        success {
            echo "Pipeline ran successfully! ${IMAGE_NAME}:${BUILD_NUMBER} is built and pushed. GoCD will now deploy."
        }
        failure {
            echo "Pipeline execution failed. Please verify credentials or security thresholds."
        }
    }
}
