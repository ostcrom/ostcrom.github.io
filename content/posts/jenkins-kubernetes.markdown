---
title: Deploying Jenkins to Kubernetes with Integration
slug: posts/jenkins-kubernetes
category: Tech Tutorial
summary: A guide showing how to use Helm to deploy Jenkins on a Kubernetes cluster and enable it to
date: 2026-01-19
tags:
  - tutorial
  - kubernetes
  - jenkins
  - cicd
  - operations
---
Deploying Jenkins to Kubernetes with Agent Integration

# Overview

In this guide, we’re going to deploy a Jenkins instance on Kubernetes using Helm and configure it to launch ephemeral build agents using the Jenkins Kubernetes plugin. The end goal is a Jenkins setup where pipeline jobs run inside short-lived Kubernetes pods instead of directly on the Jenkins controller.

I’ll walk through the steps I followed, call out places where your environment may differ from mine, and pause occasionally to explain _why_ certain pieces are configured the way they are. This guide assumes you’re already comfortable with Kubernetes fundamentals, Helm, and basic Jenkins usage.

## Prerequisites

- A Kubernetes cluster.
- An ingress controller configured for your cluster.
    - While most of this guide should work on any Kubernetes cluster, ingress configurations vary widely.
    - The ingress example later in this guide is based on K3s with Traefik and cert-manager.
    - These are the references I followed when setting up my own environment:
        - A K3s cluster with a demo application deployed:  
            [k3s.rocks: First Deploy](https://k3s.rocks/first-deploy/)
        - K3s with Traefik and Let’s Encrypt configured:  
            [k3s.rocks: HTTPS with Cert-Manager and Let's Encrypt](https://k3s.rocks/https-cert-manager-letsencrypt/)
        - Working DNS routing.
            - In my setup, the Jenkins hostname is accessible both internally and externally.
            - Internal DNS resolves to the cluster’s local IP, while external DNS resolves to its public IP.
            - DNS configuration is outside the scope of this guide.
        - Optional Traefik hardening reference:  
            [Configure Traefik to Restrict External Access to Services](https://chatgpt.com/posts/restrict-traefik-access.html)
- `kubectl` and `helm` installed and configured with access to your Kubernetes cluster.
## Prepare Kubernetes and Helm

First, we’ll create a dedicated namespace for Jenkins:
```bash
kubectl create ns jenkins
```

Next, we’ll add the Jenkins Helm repository and update it locally:
```sh
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

## Deploy Jenkins with Helm

Before deploying Jenkins, we need to create a `values.yaml` file. This file is where we’ll define most of Jenkins’ behavior, including persistence, plugin installation, RBAC configuration, and Jenkins Configuration as Code (JCasC).

Here’s the `values.yaml` file I’m using:
```yaml
controller:
  image:
    tag: "lts"

  serviceType: ClusterIP

  admin:
    create: true

  persistence:
    enabled: true
    size: 20Gi

  serviceAccount:
    create: true
    name: jenkins

  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - configuration-as-code
    - credentials
    - docker-workflow

  JCasC:
    enabled: true
    configScripts:
      kubernetes-cloud.yaml: |
        jenkins:
          clouds:
            - kubernetes:
                name: "kubernetes"
                serverUrl: "https://kubernetes.default"
                namespace: "jenkins"
                jenkinsUrl: "http://jenkins.jenkins.svc.cluster.local:8080"
                containerCap: 10
                connectTimeout: 5
                readTimeout: 15
                retentionTimeout: 5
                templates:
                  - name: "default-agent"
                    label: "k8s-agent"
                    idleMinutes: 1
                    serviceAccount: "jenkins"
                    containers:
                      - name: "jnlp"
                        image: "jenkins/inbound-agent:latest"
                        workingDir: "/home/jenkins"
                        args: "^${computer.jnlpmac} ^${computer.name}"
```

Before applying this configuration, it’s worth calling attention to two key sections: `installPlugins` and `JCasC`.

The `installPlugins` section does exactly what it sounds like. It defines the set of plugins that will be installed when Jenkins starts up. The most important one for this guide is the `kubernetes` plugin, which allows Jenkins to talk to the Kubernetes API and spin up build agent pods. The `configuration-as-code` plugin is what allows us to define Jenkins configuration directly in this YAML file instead of clicking through the UI.

The `JCasC` section is where that configuration actually lives. Here, we define a Kubernetes cloud and a single default agent template. Any pipeline that asks for an agent with the label `k8s-agent` will cause Jenkins to create a new pod using this template. Those pods are ephemeral by design and will disappear once the job finishes.

Once the file is ready, we can deploy Jenkins using Helm:
```sh
helm upgrade --install \
jenkins jenkins/jenkins \
--namespace jenkins \
--values ./values.yaml
```

After a minute or so, Helm will finish deploying the chart. The chart generates an admin password automatically, which we can retrieve with the following command:
```sh
kubectl exec --namespace jenkins \
-it svc/jenkins \
-c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password \
&& echo
```

Make a note of this password, as you’ll need it to log in to Jenkins for the first time.
## Review the Service Account and RBAC Configuration

Before moving on, it’s useful to take a quick look at what the Helm chart created from an RBAC perspective. Jenkins needs permission to create and manage pods in order to launch Kubernetes-based build agents, and these permissions are provided via a service account, roles, and role bindings.

First, list the service accounts in the `jenkins` namespace:
```sh
kubectl get serviceaccount -n jenkins
```

Example output from my cluster:
```sh
NAME      SECRETS   AGE
default   0         105m
jenkins   0         36m
```

Next, list the roles:
```sh
kubectl get roles -n jenkins
```

Example output:
```sh
NAME                      CREATED AT
jenkins-casc-reload       2026-01-19T18:04:00Z
jenkins-schedule-agents   2026-01-19T18:04:00Z
```

If you’re curious about what permissions these roles grant, `kubectl describe role <role-name>` is a helpful way to inspect them.

Finally, list the role bindings:
```sh
kubectl get rolebinding -n jenkins
```

Example output:
```sh
NAME                       ROLE                           AGE
jenkins-schedule-agents    Role/jenkins-schedule-agents   54m
jenkins-watch-configmaps   Role/jenkins-casc-reload       54m
```

This setup gives Jenkins exactly what it needs to schedule agent pods and watch for configuration changes, without granting unnecessary cluster-wide permissions.

## Jenkins Web Ingress (Optional)

If you’re using Traefik as your ingress controller, you can expose the Jenkins web interface with a configuration like the one below. This example is Traefik-specific and may not translate directly to other ingress implementations.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-tls-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.middlewares: >
      default-redirect-https@kubernetescrd,
      default-local-ip-allowlist@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - host: jenkins.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jenkins
                port:
                  number: 8080
  tls:
    - secretName: jenkins-tls
      hosts:
        - jenkins.example.com
```

## Test the Jenkins Installation

At this point, we should have a running Jenkins instance. To confirm everything is wired up correctly, we’ll create a simple pipeline job.

1. Navigate to the Jenkins web interface.
    
2. Log in with the username `admin` and the password retrieved earlier.
    
3. Select **New Item**, give the job a name, and choose **Pipeline**.
    
4. On the Pipeline configuration page, paste the following into the **Script** field and save.
    

This pipeline explicitly requests a Kubernetes-based agent using the `k8s-agent` label we defined earlier in the JCasC configuration.

```groovy
pipeline {
  agent {
    kubernetes {
      label 'k8s-agent'
    }
  }

  stages {
    stage('Test') {
      steps {
        sh 'echo hello from kubernetes agent'
        sh 'hostname'
      }
    }
  }
}
```

After saving, you’ll be taken back to the job overview page. From here, click **Build Now** and give the job a minute or two to run. While it’s running, you can use `kubectl get pods -n jenkins` to watch the agent pod appear. These pods don’t stick around for long, so timing is important.

Back in the Jenkins UI, the build should complete successfully. If you open the build and review the **Console Output**, you should see output confirming that the job ran inside a Kubernetes pod.

## Summary

At this point, Jenkins is running on Kubernetes and successfully provisioning ephemeral build agents using the Kubernetes plugin. The controller is configured entirely through Helm and Jenkins Configuration as Code, giving you a solid, repeatable foundation for building more complex pipelines on top of this setup.