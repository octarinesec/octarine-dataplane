{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "octarine.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "octarine.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "octactl.yaml" -}}
api_host: {{ .Values.api_host }}
api_port: 443
docker:
  email: {{ .Values.docker.email }}
  password: {{ .Values.docker.password }}
  username: {{ .Values.docker.username }}
embedded_ip: true
k8s_namespace: {{ .Release.Namespace }}
namespace: {{ .Values.namespace }}
restful_report: false
service_version: "1.0"
use_octarine_encryption: true
user: {{ .Values.user }}
version_tag: {{ .Values.version_tag }}
{{- end -}}

{{- define "octarine-install" -}}
# Install kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Login and bootstrap idcontroller
/octactl login --namespace {{ .Values.namespace }} --port 443 --server {{ .Values.api_host }} --username {{ .Values.user }} --password {{ .Values.password }}
/octactl idcontroller k8s --k8s-namespace {{ .Release.Namespace }} -t {{ .Values.version_tag }} -w /etc/octarine/octarine_docker_credentials {{ .Values.deployment }} | kubectl apply -f -
sleep 300000000
{{- end -}}


{{- define "dockersnippet" -}}
{{ .Values.docker.username }}:{{ .Values.docker.password }}
{{- end -}}

{{- define "octarine_docker_credentials" -}}
username={{ .Values.docker.username }}
password={{ .Values.docker.password }}
email={{ .Values.docker.email }}
{{ end -}}

{{- define "dockercfg" -}}
{"https://index.docker.io/v1/": {"username": "{{ .Values.docker.username }}","password": "{{ .Values.docker.password }}", "email": "{{ .Values.docker.email }}", "auth": "{{ include "dockersnippet" . | b64enc }}"}}
{{- end -}}
