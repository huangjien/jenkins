FROM jenkins/jenkins:lts-jdk25

USER root

# Install the baseline CLI toolchain required by legacy inline jobs that still
# execute on the controller instead of the Docker cloud agent.
ARG NODE_MAJOR=24

RUN apt-get update \
    && apt-get install -y ca-certificates curl git gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable" > /etc/apt/sources.list.d/docker.list \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get update \
    && apt-get install -y docker-ce-cli nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*

# Install Jenkins plugins from repository-managed list.
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins
