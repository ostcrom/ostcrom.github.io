# danielsteinke.com

Static site built with Pelican and deployed to GitHub Pages.

## Branch System

This repository uses a two-branch deployment model:

### `main` branch
- Contains all source content, configuration, and site code
- All changes to the site and content are pushed to `main`
- Used as the source for building the static HTML site

### `publish` branch
- Contains the generated static HTML site in the `docs/` directory
- GitHub Pages is configured to serve from the `docs/` directory on this branch
- The build process removes `docs/` from `.gitignore` before committing to this branch
- **Important**: The `CNAME` file in the `docs/` directory is required for the site to redirect correctly

## Local Development

Use the Makefile for local development tasks:

```bash
# Generate static HTML from content
make generate-html

# Serve the site locally at http://localhost:8080
make serve

# Clean generated output
make clean
```

Docker-based development is also available:

```bash
# Build the Docker image
make docker-init 

# Generate HTML using Docker
make docker-html

# Serve site using Docker
make docker-serve
```

## Jenkins Deployment

Two Jenkins pipelines automate the build and deployment process:

### Jenkinsfile.docker
Builds and pushes the Docker builder image to the container registry using Kaniko.

**Required Jenkins credentials:**
- `registry-host`: String credential containing the actual registry hostname
- `github-creds`: Username/password credential for GitHub authentication

**Required Kubernetes Secrets:**
- `docker-config`: Secret file containing Docker registry authentication

For a blank configuration, run this command:
```bash
kubectl create secret generic docker-config \
  -n BUILD_NAMESPACE \
  --from-literal=config.json='{"auths":{}}'
```

**Parameters:**
- `GIT_URL`: Repository URL (default: https://github.com/ostcrom/ostcrom.github.io.git)
- `IMAGE_NAME`: Docker image name (default: dscom-build)
- `IMAGE_TAG`: Tag for the image (default: uses BUILD_NUMBER)

### Jenkinsfile.publish
Generates the static site and publishes it to the `publish` branch for GitHub Pages. Pipeline should be configured to poll this repo `@hourly` as a trigger.

**Required Jenkins credentials:**
- `github-creds`: Username/password credential for GitHub authentication

**Parameters:**
- `GIT_URL`: Repository URL
- `MAIN_BRANCH`: Source branch containing content (default: `main`)
- `PUBLISH_BRANCH`: Target branch for deployment (default: `publish`)
- `INPUT_DIR`: Content directory (default: `content`)
- `OUTPUT_DIR`: Build output directory (default: `docs`)

**Workflow:**
1. Checks out the `main` branch
2. Switches to `publish` branch and resets to `main`
3. Builds static site using Pelican
4. Removes `docs/` from `.gitignore` and stages generated files
5. Commits generated files to `publish` branch
6. Force pushes to remote `publish` branch

## k3s Registry Configuration (Optional)

To obfuscate your registry URL in Jenkins pipelines, configure a registry alias on your k3s cluster. This allows you to reference `registry.local` in Jenkinsfiles instead of exposing the actual registry hostname.

Run the configuration script on **each k3s node**:

```bash
./configre-k3s-registry-alias.sh
```

The script will:
- Prompt for your actual registry hostname
- Configure k3s to map `registry.local` to your real registry URL
- Create `/etc/rancher/k3s/registries.yaml` with the mirror configuration
- Restart the k3s service (k3s or k3s-agent)

After configuration, reference the alias in Jenkinsfiles:

```yaml
image: registry.local/dscom-build:latest
```
