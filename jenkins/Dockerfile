FROM jenkins/jenkins:lts-jdk25

USER root

# Install Jenkins plugins from repository-managed list.
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins
