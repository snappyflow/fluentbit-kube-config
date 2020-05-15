### reference
- [https://rancher.com/docs/rke/latest/en/config-options/audit-log/](https://rancher.com/docs/rke/latest/en/config-options/audit-log/)
- [https://kubernetes.io/docs/tasks/debug-application-cluster/audit/](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/)

- [sample audit policy](audit-policy.yaml)

- [sample kube-apiserver changes](kube-apiserver.yaml)

- sample audit log
    ```json
    {
    "kind": "Event",
    "apiVersion": "audit.k8s.io/v1",
    "level": "Request",
    "auditID": "d8e35ca0-f5bb-4c1c-9a82-777c98f86a13",
    "stage": "ResponseComplete",
    "requestURI": "/api/v1/namespaces/default/services/kubernetes",
    "verb": "get",
    "user": {
        "username": "system:apiserver",
        "uid": "566c7a33-6490-411e-b426-4f8c004cb8fa",
        "groups": [
        "system:masters"
        ]
    },
    "sourceIPs": [
        "::1"
    ],
    "userAgent": "kube-apiserver/v1.18.2 (linux/amd64) kubernetes/52c56ce",
    "objectRef": {
        "resource": "services",
        "namespace": "default",
        "name": "kubernetes",
        "apiVersion": "v1"
    },
    "responseStatus": {
        "metadata": {},
        "code": 200
    },
    "requestReceivedTimestamp": "2020-05-15T10:18:45.759830Z",
    "stageTimestamp": "2020-05-15T10:18:45.762027Z",
    "annotations": {
        "authorization.k8s.io/decision": "allow",
        "authorization.k8s.io/reason": ""
    }
    }
    ```