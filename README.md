# Deploy Thunderstorm as a Container

[THOR Thunderstorm](https://www.nextron-systems.com/thor-thunderstorm/) is a web service that lets you scan files with our compromise assessment tool THOR through a Web-API. This guide provides a base [container image](https://github.com/NextronSystems/thunderstorm-deployment/pkgs/container/thunderstorm-deployment), a [Docker Compose template](https://raw.githubusercontent.com/NextronSystems/thunderstorm-deployment/master/docker-compose.yml), and a [Helm chart](charts/thunderstorm) so you can run Thunderstorm as a container with just providing your contract token.


## Quick-Start (Docker Compose)

1. Download the [Docker Compose](https://raw.githubusercontent.com/NextronSystems/thunderstorm-deployment/master/docker-compose.yml) file

```
curl -O https://raw.githubusercontent.com/NextronSystems/thunderstorm-deployment/master/docker-compose.yml
```

2. Get a contract token from the [Nextron Portal](https://portal.nextron-systems.com/ui/contracts/contracts) (see [Contract-Token](#contract-token))

3. Start the service with your contract token

```
CONTRACT_TOKEN=<CONTRACT_TOKEN> docker compose up -d
```

Thunderstorm is exposed on port **8080** by default.

## Quick-Start (Kubernetes / Helm)

A Helm chart is provided in [charts/thunderstorm](charts/thunderstorm). Requires `kubectl` connected to a cluster and `helm` 3.x.

1. Get a contract token (see [Contract-Token](#contract-token))

2. Install the chart

```
helm install thunderstorm ./charts/thunderstorm \
  --namespace thunderstorm --create-namespace \
  --set contractToken.value=<CONTRACT_TOKEN>
```

To avoid putting the token on the command line, create the Secret yourself and reference it via `--set contractToken.existingSecret=<secret-name>`.

3. Reach the API (default service type is ClusterIP)

```
kubectl -n thunderstorm port-forward svc/thunderstorm 8080:8080
curl http://localhost:8080/api/status
```

### Common overrides

All settings live in [charts/thunderstorm/values.yaml](charts/thunderstorm/values.yaml). Frequently-tuned knobs:

- `env.TECHPREVIEW=true` — opt into the THOR 11 techpreview channel
- `env.SIGNATURE_UPDATE_INTERVAL=24` — recurring signature refresh (hours)
- `persistence.size`, `persistence.storageClass` — PVC for THOR binaries and signatures
- `resources.requests` / `resources.limits` — set generous memory limits; THOR can be memory-hungry
- `service.type=LoadBalancer` or `ingress.enabled=true` — expose externally

### Expose via Cilium Gateway

If your cluster uses Cilium as the Gateway API implementation and you already have a shared `Gateway` resource, attach an `HTTPRoute` by enabling the chart's `gateway` block. The chart only creates the `HTTPRoute`; the `Gateway` is expected to already exist.

```
helm upgrade thunderstorm ./charts/thunderstorm -n thunderstorm --reuse-values \
  --set gateway.enabled=true \
  --set gateway.parentRef.name=cilium-gateway \
  --set gateway.parentRef.namespace=tooling \
  --set gateway.parentRef.sectionName=https-standard \
  --set gateway.hostnames[0]=thunderstorm.example.com
```

### Upgrade and uninstall

```
helm upgrade thunderstorm ./charts/thunderstorm -n thunderstorm -f my-values.yaml
helm uninstall thunderstorm -n thunderstorm
# The THOR binaries PVC is retained by default; delete it manually to wipe state:
# kubectl -n thunderstorm delete pvc -l app.kubernetes.io/name=thunderstorm
```

When upgrading after the chart introduces new value defaults, prefer `--reset-then-reuse-values` (Helm 3.14+) over `--reuse-values` — the latter silently drops any new defaults shipped by the chart.

## Contract-Token

Deploying Thunderstorm as a container requires a **non-host-based** Thunderstorm contract with at least one issued license.

On first start, the container uses your contract token to download the THOR binaries and persists them in a Docker volume so subsequent restarts are instant. You can omit the contract token afterwards as long as the volume exists.

A contract token can be retrieved from the [Nextron Portal](https://portal.nextron-systems.com/ui/contracts/contracts) under *Contracts & Licenses → Contracts → Actions → cloud icon → THOR Download Token*.

<img src="images/contract_token.png" alt="Contract Token location in Nextron Portal" width="500">

## Tech-Preview

If you want to use the techpreview channel (currently THOR 11) you need to set `TECHPREVIEW=1`. If it is omitted it will downgrade to the stable channel again.

The compose file contains commented environment variables for all available configuration options. Some options only apply to specific THOR major versions, for example, `QUEUE_WARN_SIZE` is only available for THOR 11.

## Signature Updates

THOR signatures are updated automatically on every container start. To keep them fresh without manually restart, set `SIGNATURE_UPDATE_INTERVAL` (in hours) to schedule recurring updates.

The update mechanism depends on the THOR major version. On THOR 10, new signatures only take effect after a restart. Docker's health check therefore marks the container as unhealthy once `SIGNATURE_UPDATE_INTERVAL` has elapsed, prompting Docker to restart it. The new signatures are then fetched as part of the regular container start, at the cost of a brief API downtime. THOR 11 uses Thunderstorm's built-in signature-update feature to download and apply signatures in-place, leaving the API available throughout.

## Additional Arguments

If you need to customize the THOR scan behavior, you can pass additional arguments via `THOR_ARGS` environment variable. For example, to forward scan results to a remote SIEM:

```yaml
environment:
  THOR_ARGS: "--remote-log splunk.intern:514:DEFAULT:TCP --remote-log elastic.intern:1514:JSON:TCP"
```

A full list of all supported arguments can be derived from the THOR binary using `./thor-linux-64 --fullhelp`.

## Security

The communication between a client and the Thunderstorm service could involve sensitive files. Therefore, we highly recommend to encrypt the traffic using TLS by mounting the certificate and private key via the built-in secrets functionality of Docker or Kubernetes into the container. In addition, you need to specify the file path to the TLS certificate and private key in the environment variables `TLS_CERT` and `TLS_KEY`.

Out of the box, Thunderstorm API is unauthenticated and does not support authentication providers at the moment. If you require an authentication layer, we suggest to use a proxy middleware which delegates the authentication to an external provider such as [Microsoft Entra ID](https://www.microsoft.com/de-de/security/business/identity-access/microsoft-entra-id).

## Limitations

### Load-Balancing
Thunderstorm allows you to send **asynchronous requests** and poll the results using an ID. Currently, Thunderstorm instances do not share their results with each other. If you run multiple Thunderstorm containers behind a load-balancer and request the results of an async request, you may not get the result from the correct Thunderstorm instance. We recommend to use async requests in combination with remote logging only in a load-balancer setup.