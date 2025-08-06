# Deploy Thunderstorm in a Container Environment

Many companies rely on the containerization of services to increase economic and technical efficiency. Customers which use containerization need to create images that make the services available as containers. In this guide, we provide you with the necessary requirements and templates to run Thunderstorm as a container.

## Containerize Thunderstorm

Thunderstorm is a web service which allows you to scan files with our compromise assessment tool THOR through a Web-API. By sane defaults, the web service listens to `127.0.0.1` on port `8000` only. However, if we want the Thunderstorm API to be accessible from anywhere, we need to adjust the binding address via command line parameter `--host`.

We created an `entrypoint.sh` which accepts optional environment variables from a Containerfile and deployment configuration. First, the shell script updates the THOR signatures to download all detection rules published after the image was created. Subsequently, the Thunderstorm executable is started which will run infinitely until the container is stopped.

### Build Container Image

The Thunderstorm binary is not publicly available and requires a non-host-based license from our portal. Therefore, we cannot provide a ready-to-use image. However, you can use the following Containerfile in combination with your contract token to build your personal Thunderstorm image.

1. Clone the repository

```
git clone https://github.com/NextronSystems/thunderstorm-deployment.git
```

2. Change to repository directory

```
cd thunderstorm-deployment/
```

3. Build image where `<TAG>` could be the Thunderstorm version and `<CONTRACT_TOKEN>` is the contract token of your non-host-based Thunderstorm license.

```
docker build -f Containerfile -t thunderstorm:<TAG> --build-args CONTRACT_TOKEN=<CONTRACT_TOKEN> .
```

4. Push image to your container registry

```
docker tag thunderstorm:<TAG> registry.internal/thunderstorm/thunderstorm:<TAG>
docker push registry.internal/thunderstorm/thunderstorm:<TAG>
```

## Signature Updates

Thunderstorm is not yet able to update signatures during runtime. Even though the feature is already planned for the next THOR release, the container currently needs to be restarted to download and apply the latest detection rules. Nevertheless, customers with high availability requirements can circumvent this limitation by using a rolling deployment and / or multiple replicas.

### Rolling Deployment

If you are running a single Thunderstorm instance, you may want to use a Rolling Deployment to prevent a downtime of your Thunderstorm service. A Rolling Deployment spawns a new container and stops the old one after ensuring that the new one is healthy and ready to accept requests. The configuration differs between container management systems such as Kubernetes, Docker or Docker Swarm.

For Docker we recommend `start-first` as value for `deploy.update_config.order`. A docker-compose template can be found under `ochestration/docker/docker-compose.yml`.

### Multiple Replicas

If you want to deploy multiple Thunderstorm instances, we recommend to distribute the requests equally using a load-balancer such as [Traefik](https://traefik.io/traefik) or [Nginx](https://nginx.org).

We created a docker-compose template for a Docker Swarm setup with Traefik under `ochestration/docker-swarm/docker-compose.yml`.

## Security

The communication between a client and the Thunderstorm service could involve sensitive files. Therefore, we highly recommend to encrypt the traffic using TLS by mounting the certificate and private key via the built-in secrets functionality of Docker or Kubernetes into the container. In addition, you need to specify the file path to the TLS certificate and private key in the environment variables `TLS_CERT` and `TLS_KEY`.

Out of the box, Thunderstorm API is unauthenticated and does not support authentication providers at the moment. If you require an authentication layer, we suggest to use a proxy middleware which delegates the authentication to an external provider such as [Microsoft Entra ID](https://www.microsoft.com/de-de/security/business/identity-access/microsoft-entra-id).