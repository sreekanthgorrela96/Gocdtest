pipeline {

    agent any

    environment {
        IMAGE_NAME = "sreekanthgorrela/flask-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sreekanthgorrela96/Gocdtest.git'
            }
        }

        stage('Build') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push') {
            steps {
                // Fixed variable names here to match the shell script usage
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Update Helm Values') {
            steps {
                // Update the tag in values.yaml
                sh """
                sed -i 's/tag:.*/tag: "${BUILD_NUMBER}"/' helm/flask-app/values.yaml
                """

                // Commit and push back to GitHub
                sh """
                git config user.email "jenkins@local"
                git config user.name "jenkins"

                git add helm/flask-app/values.yaml
                git commit -m "Updated image tag to ${BUILD_NUMBER} [skip ci]"
                git push origin main
                """
            }
        }
    }
}
