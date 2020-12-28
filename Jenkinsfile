def label = "slave-${UUID.randomUUID().toString()}"

podTemplate(label: label, cloud: 'k8s', serviceAccount: 'jenkins2', containers: [
  containerTemplate(name: 'maven', image: 'maven:3.6-alpine', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'kubectl', image: 'cnych/kubectl', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'jnlp', image: 'cnych/jenkins:jnlp6',ttyEnabled: true)
], volumes: [
  hostPathVolume(mountPath: '/root/.m2', hostPath: '/var/run/m2'),
  hostPathVolume(mountPath: '/home/jenkins/.kube', hostPath: '/root/.kube'),
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
]) {
  node(label) {
    def APP_NAME = "k8sjnekinsslave"
    def APP_PORT = "8081"
    def NODE_PORT_DEV = "30050"
    def NODE_PORT_PRO = "32050"
    def REPLICAS = "1"
    def cicd_admin = "mapleaves"
    def myRepo = checkout scm
    def gitCommit = myRepo.GIT_COMMIT
    def gitBranch = myRepo.GIT_BRANCH
    def imageTag = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    def imageEndpoint = "mapleaves/k8sjnekinsslave-${gitBranch}"
    def image = "$${imageEndpoint}:${imageTag}"
    if (gitBranch != 'dev' && gitBranch != 'master'){
      echo "${gitBranch} 分支不参与执行，开始退出，如有疑问，请联系运维人员"
      return     
    }    
    stage('单元测试') {
      echo "============================== 1.测试阶段 =============================="
      echo "branch name is ${gitBranch}"
    }
    stage('代码编译打包') {
      echo "============================== 2.代码编译打包阶段 =============================="
      try {
        container('maven') {
          sh "ls"
          sh "mvn clean package -s settings.xml -Dmaven.test.skip=true"
          sh "ls"
          sh "ls target"
        }
      } catch (exc) {
        println "构建失败 - ${currentBuild.fullDisplayName}"
        throw(exc)
      }
    }
    stage('构建 Docker 镜像') {
      echo "============================== 3.构建 Docker 镜像阶段  =============================="
      withCredentials([[$class: 'UsernamePasswordMultiBinding',
        credentialsId: 'mydockerhub',
        usernameVariable: 'dockerHubUser',
        passwordVariable: 'dockerHubPassword']]) { 
          container('docker') {   
            // 此处可以使用 harbor，这里不展开，可以参考 JenkinsfileDemo      
            sh """
            sed -i 's/<APP_PORT>/${APP_PORT}/g' Dockerfile
            docker login -u ${dockerHubUser} -p ${dockerHubPassword}
            docker build -t ${IMAGE} .
            docker push ${IMAGE}
            """ 
          }               
      }
    }
    stage('部署 $APP_NAME  到 k8s') {
      echo "============================== 4.部署 $APP_NAME ${gitBranch} 分支到 k8s =============================="
      if (gitBranch == 'master') {      
        input "确认要部署到生产环境吗？"
        NAMESPACE = "pro"
        NODE_PORT = "${NODE_PORT_PRO}"
      }
      if (gitBranch == 'dev') {
        NAMESPACE = "dev"
        NODE_PORT = "${NODE_PORT_DEV}"
      }    
      withKubeConfig([credentialsId: 'k8s',contextName: 'kubernetes-admin@kubernetes',]) {
        container('kubectl') {    
        sh """
          sed -i 's/<APP_NAME>/${APP_NAME}/g' k8s.yaml
          sed -i 's/<APP_PORT>/${APP_PORT}/g' k8s.yaml
          sed -i 's/<NODE_PORT>/${NODE_PORT}/g' k8s.yaml
          sed -i 's/<REPLICAS>/${REPLICAS}/g' k8s.yaml
          sed -i 's?<IMAGE>?${IMAGE}?g' k8s.yaml
          sed -i 's/<NAMESPACE>/${NAMESPACE}/g' k8s.yaml
          """       
        sh "kubectl apply -f k8s.yaml --record"
        }          
      }   
    }
  }
}
