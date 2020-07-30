# nginx-ssl-reverse-proxy


## Docker Compose

The following `docker-compose.yml` shows an example.
```yml
version: '3'

services: 
    reverse_proxy:
        container_name: 'reverse_proxy'
        build: './'
        ports: 
            - '80:80'
            - '443:443'
        environment: 
            - "STAGE=local"
            #- "STAGE=staging"
            #- "STAGE=production"
            - "DOMAINS=sub0.example.com, sub1.example.com -> http://othello:8080"
        volumes: 
    othello:
        container_name: 'othello'
        image: 'jumpaku/jumpaku-othello'
```

## Tests

1. Run docker-compose with the above `docker-compose.yml`.
2. Enter the container `reverse_proxy` as follows
   ```sh
   docker-compose exec reverse_proxy
   ```
3. Try the following requests.
   * The following request fails.
      ```
      curl http://localhost
      ```

   * The following request fails.
      ```
      curl -k https://localhost
      ```

   * The following request recieves 301.
      ```sh
      curl -H 'Host: sub0.example.com' http://localhost
      ```

   * The following request recieves 204.
      ```sh
      curl -k -H 'Host: sub0.example.com' https://localhost
      ```

   * The following request recieves 301.
      ```sh
      curl -H 'Host: sub1.example.com' http://localhost
      ```

   * The following request recieves 200.
      ```sh
      curl -k -H 'Host: sub1.example.com' https://localhost
      ```

