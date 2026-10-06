pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = "orderhub"
        REGISTRY = "docker.io/akanksha1822"
        APP_VERSION = "1.0.0"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.SHORT_GIT_COMMIT = sh(
                        script: "git rev-parse --short HEAD",
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
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pytest -v --junitxml=test-results.xml
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

                    sh """
                        docker build \
                          --build-arg APP_VERSION=${APP_VERSION} \
                          -t ${APP_NAME}:${BUILD_NUMBER} \
                          -t ${FULL_IMAGE} .
                    """

                    echo "Built image: ${FULL_IMAGE}"
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    docker rm -f orderhub-test || true

                    docker run -d \
                      --name orderhub-test \
                      -p 18080:8080 \
                      -e APP_VERSION=${APP_VERSION} \
                      -e BUILD_NUMBER=${BUILD_NUMBER} \
                      -e GIT_COMMIT=${GIT_COMMIT} \
                      ${FULL_IMAGE}

                    sleep 5

                    curl --fail http://localhost:18080/health

                    curl --fail http://localhost:18080/version

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
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                          -u "$DOCKER_USERNAME" \
                          --password-stdin

                        docker push ${FULL_IMAGE}

                        docker logout
                    '''
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Deploy ${FULL_IMAGE} to production?",

                      ok: "Deploy"
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
                    echo "Production deployment will use: ${FULL_IMAGE}"

                    sh '''
                        chmod +x deploy.sh

                        ./deploy.sh \
                          "${FULL_IMAGE}" \
                          "${BUILD_NUMBER}" \
                          "${GIT_COMMIT}"
                    '''
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    echo "Running production smoke test..."
                    curl --fail http://localhost:8080/health
                    curl --fail http://localhost:8080/orders
                    curl --fail http://localhost:8080/version
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
            sh '''
                docker ps -a || true
                docker images || true
            '''
        }
    }
}