pipeline {

    agent any

    environment {
        IMAGE_NAME = "sreekanthgorrela/flask-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/<yourrepo>.git'
            }
        }

        stage('Build') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Push') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Update Helm Values') {
            steps {

                sh """
                sed -i 's/tag:.*/tag: ${BUILD_NUMBER}/' helm/flask-app/values.yaml
                """

                sh """
                git config user.email "jenkins@local"
                git config user.name "jenkins"

                git add .
                git commit -m "Updated image tag ${BUILD_NUMBER}"
                git push origin main
                """
            }
        }
    }
}