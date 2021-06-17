#!/usr/bin/env groovy
pipeline {
	agent {
        node {
            label 'docker-slave'
        }
    }
    stages{
    	stage('Build docker image for API.'){
    		steps{
    			sh 'docker build . --file api.Dockerfile -t vibhoranand/toptal:web-api-$(date +"%Y%m%d")'
    		}
        }
        stage('Login and Push docker image to hub.docker.com - vibhoranand/toptal'){
                steps{
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'dockerhubPass', usernameVariable: 'dockerhubUser')]) {
                        sh 'docker login -u="$dockerhubUser" -p="$dockerhubPass"'
                        sh 'docker push vibhoranand/toptal:web-api-$(date +"%Y%m%d")'
                    }
                }
        }
    }
}