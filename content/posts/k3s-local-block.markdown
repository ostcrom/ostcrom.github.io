---
title: Restricting IP Access to a K3s Cluster with Traefik
slug: posts/restrict-traefik-access
category: Tech Tutorial
summary: A guide to restricting client access based on IP address in a K3s cluster using the default Traefik ingress.
date: 2025-04-23
---

## Motivation

In my homelab, I’ve set up a K3s cluster using the default Traefik ingress controller. Some services I run shouldn't be publicly accessible. This article explains how to configure a K3s cluster to restrict access to certain services based on the client’s IP address.

## Requirements

- A K3s cluster with a demo whoami app deployed:  
  [k3s.rocks: First Deploy](https://k3s.rocks/first-deploy/)
- K3s with Traefik and Let's Encrypt configured:  
  [k3s.rocks: HTTPS with Cert-Manager and Let's Encrypt](https://k3s.rocks/https-cert-manager-letsencrypt/)
- Working DNS routing.  
  My DNS hostname is accessible both internally and externally. Internal DNS resolves to the cluster’s local IP, while external DNS resolves to its public IP. DNS configuration is outside the scope of this guide.

## The Problem

By default, Traefik does **not** preserve the client’s original IP address. Instead, requests appear to come from the cluster IP of the ingress proxy (e.g., `10.42.0.1`). This makes it impossible to distinguish between internal and external clients by IP.

The `whoami` app helps us diagnose this. It echoes headers like `X-Real-IP`. In this image, the `X-Real-IP` is reported as `10.42.0.1`, Traefik’s internal IP—not the real client’s IP.
![Image showing X-Real-IP listed as 10.42.0.1](/images/image-whoami-internal.png){: .big-img}

## Step 1: Preserve the Client’s IP Address

To preserve the source IP, we need to update the `externalTrafficPolicy` setting on the Traefik service. This is a standard Kubernetes Service setting that, when set to `Local`, preserves the source IP. See the [Kubernetes documentation](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip) for details.

Apply the setting with:

```bash
kubectl patch svc -n kube-system \
  -p '{"spec":{"externalTrafficPolicy":"Local"}}' traefik
```

Once applied, `X-Real-IP` will show your actual LAN or WAN IP depending on where you're connecting from.

**LAN Client Example**:  
![](/images/image-whoami-lan.png){: .big-img}

**WAN Client Example**:  
![](/images/image-whoami-wan.png){: .big-img}

Now that we can differentiate clients by IP, we can block unwanted access.

### Optional: Using a YAML Patch for Persistent Configuration

 For easier reproducibility, create a patch file called `external-traffic-policy-local-patch.yaml`:

```yaml
spec:
  externalTrafficPolicy: Local
```

Then apply it with:

```bash
kubectl patch svc traefik \
  -n kube-system \
  --patch-file external-traffic-policy-local-patch.yaml
```

Same effect—just more repeatable than using CLI commands.

## Step 2: Create Middleware to Restrict IP Access

Now we’ll use a [Traefik middleware](https://doc.traefik.io/traefik/middlewares/http/ipwhitelist/) to allow only local clients.

Create the middleware definition in a YAML file, e.g., `traefik-local-ipwhitelist.yml`:

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: local-ip-allowlist
spec:
  ipWhiteList:
    sourceRange:
      - 192.168.1.0/24
```

Apply it with:

```bash
kubectl apply -f traefik-local-ipwhitelist.yml
```

Verify with:

```bash
kubectl describe middleware local-ip-allowlist
```

You should see the middleware listed and its rules.
## Step 3: Add Middleware to Your Ingress

We have created a middleware to whitelist local IP ranges, now we must update our Ingresses to use that middleware. We do this by adding an annotation to the Ingress resourcee. Let’s say you have a service like [Transmission](https://artifacthub.io/packages/helm/nicholaswilde/transmission) with this ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: transmission-tls-ingress
  annotations:
    spec.ingressClassName: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
    - host: transmission.[REDACTED].com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: transmission-service
                port:
                  number: 9091
  tls:
    - secretName: transmission-tls
      hosts:
        - transmission.[REDACTED].com
```

We configure this ingress by adding the "traefik.ingress.kubernetes.io/router.middlewares" annotation and specifying the "local-ip-allowlist" middleware we just created:

```yaml
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: >
      default-local-ip-allowlist@kubernetescrd
```

If you're using multiple middlewares, separate them with commas:

```yaml
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: >
      default-redirect-https@kubernetescrd,
      default-local-ip-allowlist@kubernetescrd
```

> ⚠️ Only the **last** `router.middlewares` key is used if defined multiple times. Combine all middlewares into one annotation.

### Example Ingress With Middleware

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: transmission-tls-ingress
  annotations:
    spec.ingressClassName: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.middlewares: >
      default-redirect-https@kubernetescrd,
      default-local-ip-allowlist@kubernetescrd
spec:
  rules:
    - host: transmission.[REDACTED].com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: transmission-service
                port:
                  number: 9091
  tls:
    - secretName: transmission-tls
      hosts:
        - transmission.[REDACTED].com
```

Now just apply the ingress configuration and we are ready to test.
```bash
kubectl apply -f ingress.yml
```


### Results: Access is Now Restricted by IP

When I access my Transmission instance from a **local** IP, it loads as expected:
![](/images/image-transmission-allowed.png){: .big-img}
When I access it from an **external** IP, I get denied:
![](/images/image-transmission-forbidden.png){: .big-img}
## Final Thoughts

Restricting services to local IPs adds an easy layer of security to your homelab or dev environment. This method is simple to implement, repeatable, and doesn’t require additional tools or services.

## Resources

- [Traefik Middleware Docs: IP Whitelist](https://doc.traefik.io/traefik/middlewares/http/ipwhitelist/)
- [Kubernetes: Preserving Source IP](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip)
- [Community Post on Real Client IP](https://community.traefik.io/t/getting-real-client-ip-x-forwarded-for-in-k3s-multi-server-ha-setup/16095)
