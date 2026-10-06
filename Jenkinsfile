@'
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = "orderhub"
        REGISTRY = "docker.io/akanksha1822"
        APP_VERSION = "1.0.1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.SHORT_GIT_COMMIT = bat(
                        script: '@git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Git Commit: ${env.GIT_COMMIT}"
                    echo "Short Commit: ${env.SHORT_GIT_COMMIT}"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Build: ${env.BUILD_NUMBER}"
                    echo "Build URL: ${env.BUILD_URL}"
                }
            }
        }

        stage('Unit Test') {
            steps {
                bat '''
                    python -m venv .jenkins-venv
                    .jenkins-venv\\Scripts\\python.exe -m pip install -r requirements.txt
                    .jenkins-venv\\Scripts\\pytest.exe -v --junitxml=test-results.xml
                '''
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}-${SHORT_GIT_COMMIT}"
                    env.FULL_IMAGE = "${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"

                    bat "docker build -t ${APP_NAME}:${BUILD_NUMBER} -t ${FULL_IMAGE} ."

                    echo "Built image: ${FULL_IMAGE}"
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                bat '''
                    docker rm -f orderhub-test 2>NUL || exit /b 0

                    docker run -d --name orderhub-test -p 18080:8080 ^
                      -e APP_VERSION=%APP_VERSION% ^
                      -e BUILD_NUMBER=%BUILD_NUMBER% ^
                      -e GIT_COMMIT=%GIT_COMMIT% ^
                      %FULL_IMAGE%

                    timeout /t 8 /nobreak >NUL

                    curl.exe --fail http://localhost:18080/health
                    curl.exe --fail http://localhost:18080/orders
                    curl.exe --fail http://localhost:18080/version

                    docker inspect orderhub-test --format "{{.State.Health.Status}}"
                    docker logs orderhub-test
                    docker rm -f orderhub-test
                '''
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    bat '''
                        echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin
                        docker push %FULL_IMAGE%
                        docker logout
                    '''
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Deploy ${FULL_IMAGE} to production?", ok: "Deploy"
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'production-server',
                        usernameVariable: 'DEPLOY_USER',
                        passwordVariable: 'DEPLOY_PASSWORD'
                    )
                ]) {
                    bat """
                        docker rm -f orderhub 2>NUL
                        docker pull ${FULL_IMAGE}
                        docker run -d --name orderhub -p 8080:8080 ^
                          -e APP_VERSION=${APP_VERSION} ^
                          -e BUILD_NUMBER=${BUILD_NUMBER} ^
                          -e GIT_COMMIT=${GIT_COMMIT} ^
                          ${FULL_IMAGE}
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                bat '''
                    timeout /t 8 /nobreak >NUL
                    curl.exe --fail http://localhost:8080/health
                    curl.exe --fail http://localhost:8080/orders
                    curl.exe --fail http://localhost:8080/version
                    docker inspect orderhub --format "{{.State.Health.Status}}"
                    docker exec orderhub whoami
                '''
            }
        }
    }

    post {
        success {
            echo "OrderHub deployment successful."
            echo "Image: ${FULL_IMAGE}"
            echo "Build: ${BUILD_NUMBER}"
            echo "Commit: ${GIT_COMMIT}"
        }

        failure {
            echo "OrderHub deployment FAILED."
        }

        always {
            bat 'docker ps -a'
            bat 'docker images orderhub'
        }
    }
}
'@ | Set-Content Jenkinsfile

