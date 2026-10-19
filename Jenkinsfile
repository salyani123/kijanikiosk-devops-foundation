pipeline {

    // Docker agent using Node.js 18 Alpine image
    agent {
        docker {
            image 'node:18-alpine'
        }
    }

    environment {
        // Nexus repository URL using IP/Gateway
        NEXUS_HOST = '172.18.0.1:8081'
        NEXUS_PATH = '/repository/kijanikiosk-npm/'
        NEXUS_URL = 'http://${NEXUS_HOST}${NEXUS_PATH}'
    }

    stages {
        stage('Lint') {
            steps {
                // npm ci for reproducible dependencies
                sh 'npm ci'
                sh 'npm run lint'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        // Parallel execution for testing and security audit
        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        sh 'npm test'
                    }
                }
                stage('Security Audit') {
                    steps {
                        sh 'npm audit'
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                sh 'npm pack'
                // Archive stage with artifacts fingerprinting
                archiveArtifacts artifacts: '*.tgz', fingerprint: true
            }
        }

        stage('Publish') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    // credentials for Nexus. .npmrc will be created and deleted within the shell script
                    sh '''
                        # Version string follows <semver>-<git-sha>
                        SHORT_SHA=$(echo ${GIT_COMMIT} | cut -c1-7)
                        CURRENT_VERSION=$(node -p "require('./package.json').version")
                        npm --no-git-tag-version version ${CURRENT_VERSION}-${SHORT_SHA}

                        # Create .npmrc, publish and delete
                        echo "registry=${NEXUS_URL}" > .npmrc
                        echo "//${NEXUS_HOST}${NEXUS_PATH}:_auth=$(echo -n ${NEXUS_USER}:${NEXUS_PASS} | base64)" >> .npmrc
                        echo "always-auth=true" >> .npmrc

                        npm publish

                        rm -f .npmrc
                    '''
                }
            }
        }
    }
    // Post block: always, success, failure, changed
    post {
        always {
            cleanWs notFailBuild: true
        }
        success {
            echo "Pipeline successful! Artifact published to ${NEXUS_URL}"
        }
        failure {
            echo "Pipeline failed. Check logs."
        }
        changed {
            echo "Pipeline status changed since the last run."
        }
    }
}