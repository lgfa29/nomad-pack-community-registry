# Nginx

This pack contains a single system job that runs Nginx and configures servers
for all services that have the `meta` value of `nomad_ingress_nginx_enabled` set
to `"true"`.

Jobs can register themselves in the ingress by annotating their service either
using `tags` or `meta` values.

```hcl
service {
  name = "webapp"
  port = "http"

  tags = [
    "nomad_ingress_nginx_enabled=true",
    "nomad_ingress_nginx_server_name=webapp.example.com",
  ]
}
```

```hcl
service {
  name = "webapp"
  port = "http"

  meta {
    nomad_ingress_nginx_enabled     = "true"
    nomad_ingress_nginx_server_name = "webapp.example.com"
  }
}
```

### Running a local example

Start a local Nomad and Consul agent. If you are not on Linux, refer to this
[FAQ entry][nomad_docs_faq] so your containers can communicate properly.

The Nginx ingress uses hostnames to route requests to the appropriate service.
When testing locally, you can add entries to your `/etc/hosts` file to simulate
a DNS server.

In this example, you will use the `hello_world` pack, so add an entry like this
to you `/etc/hosts` file:

```
...
<YOUR_IP> hello.example.com
```

If you are on Linux you can set `<YOUR_IP>` to `127.0.0.1`, otherwise use the IP
address defined in your Consul agent `-bind` configuration from the previous
step.

Now, when you access `hello.example.com` your system will resolve to your own IP
address.

Run the nginx ingress pack:

```shell-session
$ nomad-pack run -var domain=example.com nginx
```

Now run the `hello_world` pack specifying service tags that will automatically
register it to the Nginx ingress:

```shell-session
$ nomad-pack run -var 'consul_service_tags=["nomad_ingress_nginx_enabled=true","nomad_ingress_nginx_server_name=hello.example.com"]'
```

Open your browser and navigate to http://hello.example.com:8082 and verify that
your service is reachable.

## Dependencies

This pack requires Linux clients to run.

## Variables

- `http_port` (number) - The Nomad client port that routes to the Nginx. This port will be where you visit your load balanced application
- `version_tag` (string) - The docker image version. For options, see https://hub.docker.com/_/nginx
- `resources` (object) - The resource to assign to the Nginx system task that runs on every client
- `job_name` (string) - The name to use as the job name which overrides using the pack name
- `datacenters` (list of string) - A list of datacenters in the region which are eligible for task placement
- `region` (string) - The region where the job should be placed
- `namespace` (string) - The namespace where the job should be placed
- `type` (string) - The scheduler to use for the job
- `default_domain` - The default domain to use when the service doesn't define a server name

[nomad_docs_faq]: https://www.nomadproject.io/docs/faq#q-how-to-connect-to-my-host-network-when-using-docker-desktop-windows-and-macos
