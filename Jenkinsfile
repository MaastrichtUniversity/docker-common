pipeline {
  agent any
  stages {
    stage('git clone') {
      steps {
        git(url: 'https://github.com/MaastrichtUniversity/docker-common.git', branch: 'master')
      }
    }
    stage('check files') {
      steps {
        sh '''#!/bin/bash
file="docker-compose.yml"
if [ -f "$file" ]
then
	echo "$file found."
        exit 0
else
	echo "$file not found."
        exit 1
fi
'''
      }
    }
  }
}