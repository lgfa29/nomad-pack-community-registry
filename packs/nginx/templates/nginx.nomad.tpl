job [[ template "job_name" . ]] {
  [[ template "region" . ]]
  datacenters = [ [[ range $idx, $dc := .nginx.datacenters ]][[if $idx]],[[end]][[ $dc | quote ]][[ end ]] ]
  namespace   = [[ .nginx.namespace | quote ]]
  type        = [[ .nginx.type | quote ]]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = [[ .nginx.http_port ]]
      }
    }

    service {
      name = "nginx"
      port = "http"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:[[ .nginx.version_tag ]]"
        ports = ["http"]

        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
{{- range services -}}
{{- with service .Name -}}
{{- with index . 0 }}
{{- if eq (index .ServiceMeta "nomad_ingress_nginx_enabled") "true" }}
# Configuration for service {{ .Name }}.
# This block is automatically managed by this job and should not be modified.
upstream {{ .Name | toLower }} {
  {{- range service .Name }}
  server {{ .Address }}:{{ .Port }};
  {{- end }}
}

server {
   listen [[ .nginx.http_port ]];
   {{- if (index .ServiceMeta "nomad_ingress_nginx_server_name") }}
   server_name {{ index .ServiceMeta "nomad_ingress_nginx_server_name" }};
   {{- else }}
   server_name {{ .Name}}.[[ .nginx.domain ]];
   {{- end }}

   location / {
      proxy_pass http://{{ .Name | toLower }};
   }
}
{{ else if .Tags | contains "nomad_ingress_nginx_enabled=true" }}
# Configuration for service {{ .Name }}.
# This block is automatically managed by this job and should not be modified.
upstream {{ .Name | toLower }} {
  {{- range service .Name }}
  server {{ .Address }}:{{ .Port }};
  {{- end }}
}

server {
   listen [[ .nginx.http_port ]];
   {{- $server_name_key := (print "server_name_" .Name) -}}
   {{- range .Tags -}}
   {{- if eq (index (. | split "=") 0) "nomad_ingress_nginx_server_name" -}}
   {{- scratch.Set $server_name_key (index (. | split "=")  1) -}}
   {{- end -}}
   {{- end -}}
   {{ if scratch.Key $server_name_key }}
   server_name {{ scratch.Get $server_name_key }};
   {{- else }}
   server_name {{ .Name}}.[[ .nginx.domain ]];
   {{- end }}

   location / {
      proxy_pass http://{{ .Name | toLower }};
   }
}
{{ end }}
{{- end -}}
{{- end -}}
{{ end }}
EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu    = [[ .nginx.resources.cpu ]]
        memory = [[ .nginx.resources.memory ]]
      }
    }
  }
}
