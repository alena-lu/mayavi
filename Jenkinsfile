pipeline {
  // make agent pod
  agent {
    kubernetes {
      yamlFile 'sonar-agent.yaml'
    }
  }

  // AI citation: used to help me find https://www.jenkins.io/doc/book/pipeline/syntax/#triggers 
  triggers {
    pollSCM('H/2 * * * *')
  }

  environment {
    SONAR_HOST_URL = 'http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000'
    SONAR_TOKEN = credentials('sonar-token')
  }
  // ref: https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/
  stages {
    stage('SonarQube Analysis') {
      steps {
        container('sonar-scanner') {
          sh '''
            sonar-scanner \
              -Dsonar.projectKey=mayavi \
              -Dsonar.sources=. \
              -Dsonar.python.version=3 \
              -Dsonar.qualitygate.wait=true \
              -Dsonar.qualitygate.timeout=600
          '''
        }
      }
    }

    stage('Run Hadoop Job') {
      steps {
        echo 'Quality gate passed: no Blocker/Critical/Major issues.'
      }
    }
  }
}