pipeline {
    agent any

    environment {
        IMAGE_NAME = "sreekanthgorrela/flask-app"
        
        // Define your Jenkins Credentials IDs here for clean maintainability
        DOCKER_CREDS_ID = 'dockerhub'
        GIT_CREDS_ID    = 'github-token2' // Ensure this matches your Jenkins credentials ID
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
                // The --ignore-unfixed flag allows the build to pass when no patch is available online
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${TAG}"
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
                // Wrap this in your GitHub credential block so git push actually succeeds
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
            // Wipes out local workspace files to keep build agents clear
            cleanWs()
            
            // Wipes built images out of the host daemon memory to prevent disk exhaustion
            sh "docker rmi ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest || true"
        }
        success {
            echo "Pipeline ran successfully! ${IMAGE_NAME}:${BUILD_NUMBER} is live."
        }
        failure {
            echo "Pipeline execution failed. Please verify credentials or security thresholds."
        }
    }
}
