pipeline {
  agent any
  stages {
    stage('git clone') {
      steps {
        git(url: 'https://github.com/MaastrichtUniversity/docker-common.git', branch: 'master')
      }
    }
  }
}