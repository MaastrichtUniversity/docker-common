pipeline {
  agent any
  environment {
        COMPOSE_PROJECT_NAME = 'common'
        RIT_ENV = 'dev6'
      }
  stages {
	stage('clean workspace and docker') {
            steps {
                cleanWs()
				sh 'docker system prune -a --volumes -f'
            }
        }
    stage('git clone') {   
      steps {
        slackSend color: "#439FE0", message: "Build Started - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
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
        sh 'docker-compose build --pull --no-cache'
        //sh 'docker-compose build'
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
      steps {
        //sh 'docker-compose up'
		sh 'docker-compose up -d'
        sleep(unit: 'MINUTES', time: 1)
      }
    }
    stage('check for exited') {
      steps {
        sh '''#!/bin/bash
    var=$(docker-compose ps | grep Exit)
    if [ -z "$var" ]
    then
    	echo "$var up"
            exit 0
    else
    	echo "$var down"
            exit 1
fi
'''
      }
    }
      stage('inside a container') {
      steps {
        sh 'docker exec -i ${COMPOSE_PROJECT_NAME}_elk_1 service elasticsearch status'
        sh 'docker exec -i ${COMPOSE_PROJECT_NAME}_proxy_1 service nginx status'
        sh 'docker exec -i ${COMPOSE_PROJECT_NAME}_logspout_1 hostname '
      }
    }
    stage('git clone selenium') {
      steps {
        dir('selenium_test'){	
            git(url: 'ssh://git@bitbucket.rit.unimaas.nl:7999/ritdev/selenium_tests.git',credentialsId: 'SHH-private-key', branch: 'docker_common')
        }
      }
    }
    stage('docker build selenium test') {
      steps {
        dir('selenium_test'){
        sh 'docker build -t selenium_docker_common_test .'
        }
      }
    }
    stage('docker run selenium test') {
      steps {
        dir('selenium_test'){
            sh "docker volume create selenium-data-${env.JOB_NAME}"
            sh "docker run -e RIT_ENV=${RIT_ENV} --name selenium_docker_common_test --mount source=selenium-data-${env.JOB_NAME},target=/usr/src/app/test-results selenium_docker_common_test"
        }
      }
	  post {
		always {
			dir('selenium_test'){
			dir('test_results'){ writeFile file:'dummy', text:''
            sh "docker run -v selenium-data-${env.JOB_NAME}:/data --name helper busybox true"
            sh 'docker cp helper:/data .'
			sh 'docker rm helper'
			}
			}
		}
	  }
    }
  }
  post {
       always {
            sh "docker-compose down"
            sh 'docker rm selenium_docker_common_test'
            sh "docker volume rm selenium-data-${env.JOB_NAME}"
            archiveArtifacts artifacts: 'selenium_test/test_results/data/**'
            junit 'selenium_test/test_results/data/*.xml'
       }
       success {
           slackSend color: "#00ff04", message: "WAUW amazing :) - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
		   echo 'succes'
       }
       failure {
           slackSend color: "#ff0000", message: "Fail better!! - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
		   echo 'fail'
       }
   }
}
