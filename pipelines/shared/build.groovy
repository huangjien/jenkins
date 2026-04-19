def call(Map config = [:]) {
  def image = config.get('image', 'maven:3.9.8-eclipse-temurin-17')

  pipeline {
    agent {
      docker {
        image image
      }
    }

    stages {
      stage('Compile') {
        steps {
          sh 'mvn -B -ntp clean compile'
        }
      }

      stage('Unit Test') {
        steps {
          sh 'mvn -B -ntp test'
        }
      }
    }
  }
}
