# HPE notes

Hand-crafted Helm chart to run the **Open OnDemand** web portal on HPE Private
Cloud AI (PCAI / Ezmeral Unified Analytics).

- Upstream project: https://github.com/OSC/ondemand
- Kubernetes resource-manager docs (session-per-pod):
  https://osc.github.io/ood-documentation/latest/installation/resource-manager/kubernetes.html

PCAI integration follows the same pattern as the other frameworks in this repo
(Istio `VirtualService`, `hpe-ezua/*` pod labels, PVC, configurable image); the
GPU reference chart is `../docling/1.35.0`.

Read [README.md](./README.md) for the architecture, the **honest feasibility
assessment** (what works as a plain namespaced import vs. what needs a PCAI
cluster admin), the session-per-pod details, and the GPU example.
