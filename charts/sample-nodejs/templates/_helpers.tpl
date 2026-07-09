{{/*
Common labels applied to every object. "helm.sh/chart" ties resources
to the chart version; the app.kubernetes.io/* labels are the k8s
recommended-label convention.
*/}}
{{- define "sample-nodejs.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — the immutable subset used by Deployment.spec.selector
and Service.spec.selector. Never include version here: selectors are
immutable, so a version label would break upgrades.
*/}}
{{- define "sample-nodejs.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
