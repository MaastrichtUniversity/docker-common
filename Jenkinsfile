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
    stage('docker-compose build') {
      steps {
        sh 'docker-compose build'
      }
    }
    stage('docker networks') {
      steps {
        sh '''if ! docker network inspect corpus_default > /dev/null 2>&1; then
   docker network create corpus_default
fi
if ! docker network inspect oculus_default > /dev/null 2>&1; then
   docker network create oculus_default
fi'''
      }
    }
    stage('docker-compose up') {
      environment {
        COMPOSE_PROJECT_NAME = 'common'
        RIT_ENV = 'dev6'
      }
      steps {
        sh 'docker-compose up -d'
        sleep(unit: 'MINUTES', time: 3)
      }
    }
  }
}