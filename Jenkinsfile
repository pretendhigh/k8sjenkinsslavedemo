node("mapleaves") {
  def APP_NAME = "javawebdemo"
  def APP_PORT = "8081"
  def NODE_PORT_DEV = "30040"
  def NODE_PORT_PRO = "32040"
  def REPLICAS = "1"
  def cicd_admin = "mapleaves"
  def myRepo = checkout scm
  def gitCommit = myRepo.GIT_COMMIT
  def gitBranch = myRepo.GIT_BRANCH
  def imageTag = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
  def imageEndpoint = "mapleaves/javawebdemo-${gitBranch}"
  def IMAGE = "${imageEndpoint}:${imageTag}"  
  if (gitBranch != 'dev' && gitBranch != 'master'){
    echo "${gitBranch} 分支不参与执行，开始退出，如有疑问，请联系运维人员 ${cicd_admin}"
    return     
  }    
  stage('SonarQube 代码检测') {
    echo "============================== 1.代码检测阶段 =============================="
    echo "branch name is ${gitBranch}"
    if (gitBranch == 'dev' ){
        echo "branch name is ${gitBranch}"
        // 此处可以调用 sonarqube，这里不展开，可以参考 jenkinsfile-demo
    } else {
      echo "${gitBranch} 分支不做代码检测，如有疑问，请联系运维人员 ${cicd_admin}"
    }
  }
  stage('代码编译打包') {
    echo "============================== 2.代码编译打包阶段 =============================="
    try {
      sh "ls"
      sh "ls target"
      sh "mvn clean package -s settings.xml -Dmaven.test.skip=true"
      sh "ls"
      sh "ls target"      
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
      // 此处可以使用 harbor，这里不展开，可以参考 jenkinsfile-demo
      sh """
      sed -i 's/<APP_PORT>/${APP_PORT}/g' Dockerfile
      docker login -u ${dockerHubUser} -p ${dockerHubPassword}
      docker build -t ${IMAGE} .
      docker push ${IMAGE}
      """        
    }
  }
  stage('部署 recommend-system 到 infra-k8s') {
    echo "============================== 4.部署 recommend-system ${gitBranch} 分支到 infra-k8s =============================="
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
