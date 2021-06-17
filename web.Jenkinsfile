#!/usr/bin/env groovy
pipeline {
	agent {
        node {
            label 'docker-slave'
        }
    }
    stages{
    	stage('Build docker image for web frontend.'){
    		steps{
    			sh 'docker build . --file web.Dockerfile -t vibhoranand/toptal:web-frontend-$(date +"%Y%m%d")'
    		}
        }
        stage('Login and Push docker image to hub.docker.com - vibhoranand/toptal'){
                steps{
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'dockerhubPass', usernameVariable: 'dockerhubUser')]) {
                        sh 'docker login -u="$dockerhubUser" -p="$dockerhubPass"'
                        sh 'docker push vibhoranand/toptal:web-frontend-$(date +"%Y%m%d")'
                    }
                }
        }
    }
}