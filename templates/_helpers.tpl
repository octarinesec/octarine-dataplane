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
namespace: {{ .Values.octarine_namespace }}
restful_report: false
service_version: "1.0"
use_octarine_encryption: true
user: {{ .Values.user }}
version_tag: {{ .Values.version_tag }}
{{- end -}}

{{- define "octarine-install" -}}
# Login and bootstrap idcontroller
octactl config docker.email {{ .Values.docker.email }}
octactl config docker.username {{ .Values.docker.username }}
octactl config docker.password {{ .Values.docker.password }}
octactl config use_quotas {{ default "true" .Values.use_quotas }}
octactl login --namespace {{ .Values.octarine_namespace }} --api_port 443 --api_host {{ .Values.api_host }} --user {{ .Values.user }} --password {{ .Values.password }}
octactl deployment create {{ .Values.deployment }}
octactl idcontroller {{ .Values.deployment }} --k8s-namespace {{ .Release.Namespace }} -t {{ .Values.version_tag }} | kubectl apply -f -
octactl sidecar-injector sidecar-injector-{{ .Values.deployment }} {{ .Values.deployment }} --k8s-namespace {{ .Release.Namespace }} --idcontroller-host idcontroller.{{ .Release.Namespace }} | kubectl apply -f -
{{- range .Values.k8s_namespaces }}
octactl sidecar-injector enable --k8s-namespace {{ . }}
{{- end }}
{{- end -}}

{{- define "octarine-cleanup" -}}
# Login and bootstrap idcontroller
octactl config docker.email {{ .Values.docker.email }}
octactl config docker.username {{ .Values.docker.username }}
octactl config docker.password {{ .Values.docker.password }}
octactl login --namespace {{ .Values.octarine_namespace }} --api_port 443 --api_host {{ .Values.api_host }} --user {{ .Values.user }} --password {{ .Values.password }}
octactl deployment delete {{ .Values.deployment }}
{{- range .Values.k8s_namespaces }}
octactl sidecar-injector disable --k8s-namespace {{ . }}
{{- end }}
kubectl delete mutatingwebhookconfiguration octarine-sidecar-injector
octactl sidecar-injector sidecar-injector-{{ .Values.deployment }} {{ .Values.deployment }} --k8s-namespace {{ .Release.Namespace }} --idcontroller-host idcontroller.{{ .Release.Namespace }} | kubectl delete -f -
kubectl delete deployment octarine-sidecar-injector --namespace {{ .Release.Namespace }}
octactl idcontroller {{ .Values.deployment }} --k8s-namespace {{ .Release.Namespace }} -t {{ .Values.version_tag }} | kubectl delete -f -
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
