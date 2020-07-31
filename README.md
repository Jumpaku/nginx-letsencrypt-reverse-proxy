# nginx-letsencrypt-reverse-proxy

A docker image of reverse proxy.

* It routes requests based on host fields of request headers.
* It redirects all HTTP requests to HTTPS.
* It obtains and renews Let's Encrypt certificates automatically.

## Environments

| environment | default         | required | description |
|-------------|-----------------|----------|-------------|
| `RENEW_SCHED`    | `0 0 1 * *` | no       | schedule of certificates renewal attempts  |
| `DOMAINS`   | ` `            | no       | domains and their routings |
| `STAGE`      |  `local`               | no      | stage to deploy |


* `RENEW_SCHED` is specified as a cron expression. See https://crontab.guru.
* `DOMAINS` is specified as a `,` separated sequense, each element of which is represented as `domain` or `domain -> URL`.
   * For each element represented as `domain`, the container obtains and renews certificate of the `domain`.
   * For each element represented as `domain -> URL`, in addition to the above, the container routes requests with the `domain` to the specified `URL`.
* `STAGE` is specified as one of `local`, `staging` or `production`.
   * If `local` is specified, the container obtains and renews self signed certificates.
   * If `staging` is specified, the container obtains and renews Let's Encrypt certificates for testing.
   * If `production` is specified, the container obtains and renews Let's Encrypt certificates for publishing.

## Volumes

### `/certificates/`

Obtained certificates are placed at `/certificates/STAGE/domain/` in the container. 

## Example

1. Run docker-compose with the following `docker-compose.yml`.
   ```yml
   version: '3'

   services: 
      reverse_proxy:
         container_name: 'reverse_proxy'
         image: 'jumpaku/nginx-letsencrypt-reverse-proxy'
         ports: 
               - '80:80'
               - '443:443'
         environment: 
               - "RENEW_SCHED="
               - "STAGE=local"
               #- "STAGE=staging"
               #- "STAGE=production"
               - "DOMAINS=sub0.example.com, sub1.example.com -> http://othello:8080"
         volumes: 
               - "./certificates:/certificates"
      othello:
         container_name: 'othello'
         image: 'jumpaku/jumpaku-othello'
   ```
2. Enter the container `reverse_proxy`.
   ```sh
   docker-compose exec reverse_proxy bash
   ```
3. Try the following requests.
   ```sh
   curl http://localhost
   # => fails
   ```
   ```sh
   curl -k https://localhost
   # => fails
   ```
   ```sh
   curl -H 'Host: sub0.example.com' http://localhost
   # => 301
   ```
   ```sh
   curl -k -H 'Host: sub0.example.com' https://localhost
   # => 204
   ```
   ```sh
   curl -H 'Host: sub1.example.com' http://localhost
   # => 301
   ```
   ```sh
   curl -k -H 'Host: sub1.example.com' https://localhost
   # => 200
   ```
4. Check obtained certificates at `./certificates/` in host machine.
