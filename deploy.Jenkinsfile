pipeline {
    agent {
        node {
            label 'docker-slave'
        }
    }
    environment {
        PROJECT_ID = 'dynamic-concept-305518'
        CLUSTER_NAME = 'node-3tier-app-prod'
        LOCATION = 'us-central1'
        CREDENTIALS_ID = 'dynamic-concept-305518'
    }
    stages {
        stage("Checkout code") {
            steps {
                checkout scm
            }
        }
        stage("Build images") {
            steps {
                script {
                    webappfrontend = docker.build("dynamic-concept-305518/web-frontend:${env.BUILD_ID}" , "--file web.Dockerfile ./")
                    webappapi = docker.build("dynamic-concept-305518/web-api:${env.BUILD_ID}" , "--file api.Dockerfile ./")
                }
            }
        }
        stage("Push image") {
            steps {
                script {
                    docker.withRegistry('https://gcr.io', 'gcr:dynamic-concept-305518') {
                            webappfrontend.push("latest")
                            webappfrontend.push("${env.BUILD_ID}")
                            webappapi.push("latest")
                            webappapi.push("${env.BUILD_ID}")
                    }
                }
            }
        }
        stage('Deploy to GKE') {
            steps{
                sh "sed -i 's/web-api:latest/web-api:${env.BUILD_ID}/g' kubernetes/api.yaml"
                sh "sed -i 's/web-frontend:latest/web-frontend:${env.BUILD_ID}/g' kubernetes/frontend.yaml"
                script  {
                    def yamlFiles = ['namespace.yaml','postgres-svc.yaml','api.yaml','frontend.yaml','api-autoscaling.yaml','frontend-autoscaling.yaml','ingress.yaml','api-autoscaling.yaml','es_statefulset.yaml','elasticsearch_svc.yaml','fluentd.yaml','kibana.yaml' ]
                    yamlFiles.each(){
                        echo "deploying kubernetes/${it}"
                        step([$class: 'KubernetesEngineBuilder', projectId: env.PROJECT_ID, clusterName: env.CLUSTER_NAME, location: env.LOCATION, manifestPattern: "kubernetes/${it}", credentialsId: env.CREDENTIALS_ID, verifyDeployments: false])
                    }

                    def grafanaFiles = ['monitoring-namespace.yaml','clusterRole.yaml','config-map.yaml','prometheus-deployment.yaml','prometheus-service.yaml','grafana-datasource-config.yaml','grafana-pvc.yaml','grafana-deployment.yaml','grafana-service.yaml']
                    grafanaFiles.each(){
                        echo "deploying kubernetes-grafana/${it}"
                        step([$class: 'KubernetesEngineBuilder', projectId: env.PROJECT_ID, clusterName: env.CLUSTER_NAME, location: env.LOCATION, manifestPattern: "kubernetes-grafana/${it}", credentialsId: env.CREDENTIALS_ID, verifyDeployments: false])
                    }
                }
            }
        }
    }
}