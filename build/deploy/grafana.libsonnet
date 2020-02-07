local base = import 'base.libsonnet';

{
	all(metadata) : {
		configMap: base.ConfigMap(metadata, 'grafana-datasources') {
			metadata: {
				name: 'grafana-datasources',
				namespace: metadata.namespace,
			},
			data: {
				'prometheus.yaml': '{\n    "apiVersion": 1,\n    "datasources": [\n        {\n           "access":"proxy",\n            "editable": true,\n            "name": "prometheus",\n            "orgId": 1,\n            "type": "prometheus",\n            "url": "http://prometheus-service.' + metadata.namespace + '.svc:8080",\n            "version": 1\n        }\n    ]\n}',
			},
		},
		deployment: base.Deployment(metadata, 'grafana') {
			metadata: {
				name: 'grafana',
				namespace: metadata.namespace,
			},
			spec: {
				replicas: 1,
				selector: {
					matchLabels: {
						app: 'grafana',
					},
				},
				template: {
					metadata: {
						name: 'grafana',
						labels: {
							app: 'grafana',
						},
					},
					spec: {
						containers: [
							{
								name: 'grafana',
								image: 'grafana/grafana:latest',
								ports: [
									{
										name: 'grafana',
										containerPort: 3000,
									},
								],
								resources: {
									limits: {
										memory: '2Gi',
										cpu: '1000m',
									},
									requests: {
										memory: '1Gi',
										cpu: '500m',
									},
								},
								volumeMounts: [
									{
										mountPath: '/var/lib/grafana',
										name: 'grafana-storage',
									},
									{
										mountPath: '/etc/grafana/provisioning/datasources',
										name: 'grafana-datasources',
										readOnly: false,
									},
								],
							},
						],
						volumes: [
							{
								name: 'grafana-storage',
								emptyDir: {},
							},
							{
								name: 'grafana-datasources',
								configMap: {
									defaultMode: 420,
									name: 'grafana-datasources',
								},
							},
						],
					},
				},
			},
		},
		service: base.Service(metadata, 'grafana') {
			metadata: {
				name: 'grafana',
				namespace: metadata.namespace,
				annotations: {
					'prometheus.io/scrape': 'true',
					'prometheus.io/port': '3000',
				},
			},
			spec: {
				selector: {
					app: 'grafana',
				},
				type: 'NodePort',
				ports: [
					{
						port: 3000,
						targetPort: 3000,
						nodePort: 32000,
					},
				],
			},
		},
	},
}