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
                    "C:/Users/akank/AppData/Local/Programs/Python/Python311/python.exe" -m venv .jenkins-venv
                    if errorlevel 1 exit /b 1

                    .jenkins-venv\\Scripts\\python.exe -m pip install -r requirements.txt
                    if errorlevel 1 exit /b 1

                    .jenkins-venv\\Scripts\\pytest.exe -v --junitxml=test-results.xml
                    if errorlevel 1 exit /b 1
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
                    docker rm -f orderhub-test 2>NUL || echo No existing test container

                    docker run -d --name orderhub-test -p 18080:8080 ^
                      -e APP_VERSION=%APP_VERSION% ^
                      -e BUILD_NUMBER=%BUILD_NUMBER% ^
                      -e GIT_COMMIT=%GIT_COMMIT% ^
                      %FULL_IMAGE%

                    if errorlevel 1 exit /b 1

                    powershell -NoProfile -Command "Start-Sleep -Seconds 10"

                    curl.exe --fail http://localhost:18080/health
                    if errorlevel 1 (
                        docker logs orderhub-test
                        exit /b 1
                    )

                    curl.exe --fail http://localhost:18080/orders
                    if errorlevel 1 (
                        docker logs orderhub-test
                        exit /b 1
                    )

                    curl.exe --fail http://localhost:18080/version
                    if errorlevel 1 (
                        docker logs orderhub-test
                        exit /b 1
                    )

                    docker inspect orderhub-test --format "{{.State.Health.Status}}"

                    docker inspect orderhub-test --format "{{.State.Health.Status}}" | findstr /I "healthy"
                    if errorlevel 1 (
                        docker logs orderhub-test
                        exit /b 1
                    )

                    docker logs orderhub-test

                    docker rm -f orderhub-test
                    if errorlevel 1 exit /b 1
                '''
            }

            post {
                always {
                    bat 'docker rm -f orderhub-test 2>NUL || echo Test container already removed'
                }
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'dockerhub-token',
                        variable: 'DOCKER_TOKEN'
                    )
                ]) {
                    bat '''
                        powershell -NoProfile -Command "$env:DOCKER_TOKEN | docker login -u akanksha1822 --password-stdin"

                        if errorlevel 1 (
                            echo Docker Hub login FAILED.
                            exit /b 1
                        )

                        docker push %FULL_IMAGE%

                        if errorlevel 1 (
                            echo Docker image push FAILED.
                            docker logout
                            exit /b 1
                        )

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
                bat """
                    "C:\\Program Files\\Git\\bin\\bash.exe" ./deploy.sh ^
                        "${FULL_IMAGE}" ^
                        "${BUILD_NUMBER}" ^
                        "${GIT_COMMIT}"
                """
            }
        }

        stage('Smoke Test') {
            steps {
                bat '''
                    powershell -NoProfile -Command "Start-Sleep -Seconds 10"

                    curl.exe --fail http://localhost:8080/health
                    if errorlevel 1 (
                        docker logs orderhub
                        exit /b 1
                    )

                    curl.exe --fail http://localhost:8080/orders
                    if errorlevel 1 (
                        docker logs orderhub
                        exit /b 1
                    )

                    curl.exe --fail http://localhost:8080/version
                    if errorlevel 1 (
                        docker logs orderhub
                        exit /b 1
                    )

                    docker inspect orderhub --format "{{.State.Health.Status}}"

                    docker inspect orderhub --format "{{.State.Health.Status}}" | findstr /I "healthy"
                    if errorlevel 1 (
                        docker logs orderhub
                        exit /b 1
                    )

                    docker exec orderhub whoami
                    if errorlevel 1 exit /b 1
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