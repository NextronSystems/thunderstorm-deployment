# Deploy Thunderstorm in a Container Environment

Many companies rely on the containerization of services to increase economic and technical efficiency. Customers which use containerization need to create images that make the services available as containers. In this guide, we provide you with the necessary requirements and templates to run Thunderstorm as a container.

## Quick Start

Thunderstorm is a web service which allows you to scan files with our compromise assessment tool THOR through a Web-API. A ready-to-use base image is published to the GitHub Container Registry and only requires your contract token to run.

1. Download the `docker-compose.yml` from this repository

```
curl -O https://raw.githubusercontent.com/NextronSystems/thunderstorm-deployment/master/docker-compose.yml
```

2. Start the service with your contract token

```
CONTRACT_TOKEN=<CONTRACT_TOKEN> docker compose up -d
```

On first start, Thunderstorm downloads the THOR binaries using your `CONTRACT_TOKEN` (your non-host-based Thunderstorm license) and persists them in a Docker volume so subsequent restarts are instant. THOR signatures are updated automatically on every start and periodically while running.

The `docker-compose.yml` contains commented environment variables for all available configuration options such as TLS, port, queue size, and signature update interval.

## Signature Updates

By default, Thunderstorm tries to download new THOR signatures every 24 hours while running. You should keep in mind that the THOR signature release cycle may differ, so there is not always a new package available. The signature update interval can be modified on an hourly basis by specifying the environment variable `SIGNATURE_UPDATE_INTERVAL` in the `docker-compose.yml`.

### Rolling Deployment

If you are running a single Thunderstorm instance, you may want to use a Rolling Deployment to prevent a downtime of your Thunderstorm service. A Rolling Deployment spawns a new container and stops the old one after ensuring that the new one is healthy and ready to accept requests. The configuration differs between container management systems such as Kubernetes, Docker or Docker Swarm.

For Docker we recommend `start-first` as value for `deploy.update_config.order`, as configured in the `docker-compose.yml` at the repository root.

### Multiple Replicas

If you want to deploy multiple Thunderstorm instances, we recommend to distribute the requests equally using a load-balancer such as [Traefik](https://traefik.io/traefik) or [Nginx](https://nginx.org).

## Passing Additional Arguments

Any argument supported by Thunderstorm or THOR can be passed via the `THUNDERSTORM_ARGS` and `THOR_ARGS` environment variables in `docker-compose.yml`. This means new parameters released in future versions are available immediately without any changes to the image or entrypoint.

For example, to forward scan results to a remote SIEM:

```yaml
environment:
  THOR_ARGS: "--remote-log splunk.intern:514:DEFAULT:TCP --remote-log elastic.intern:1514:JSON:TCP"
```

## Security

The communication between a client and the Thunderstorm service could involve sensitive files. Therefore, we highly recommend to encrypt the traffic using TLS by mounting the certificate and private key via the built-in secrets functionality of Docker or Kubernetes into the container. In addition, you need to specify the file path to the TLS certificate and private key in the environment variables `TLS_CERT` and `TLS_KEY`.

Out of the box, Thunderstorm API is unauthenticated and does not support authentication providers at the moment. If you require an authentication layer, we suggest to use a proxy middleware which delegates the authentication to an external provider such as [Microsoft Entra ID](https://www.microsoft.com/de-de/security/business/identity-access/microsoft-entra-id).
