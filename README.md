# nginx-ssl-reverse-proxy

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

