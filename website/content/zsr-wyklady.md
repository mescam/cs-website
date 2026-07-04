+++
title = 'Zarządzanie Systemami Rozproszonymi - wykład'
date = 2026-07-04T12:00:00+02:00
draft = false
+++

Semestr zimowy 2026/27

## Cel przedmiotu

Zapoznanie studentów z nowoczesnymi praktykami zarządzania systemami rozproszonymi — od konteneryzacji i orkiestracji, przez automatyzację infrastruktury i bezpieczeństwo, aż po architektury chmurowe i zgodność regulacyjną.

## Plan wykładów

### 1. Wprowadzenie do DevOps i współczesnego administrowania
- Ewolucja ról: sysadmin → DevOps engineer → SRE → Platform Engineer
- Filozofia DevOps — model CALMS (Culture, Automation, Lean, Measurement, Sharing)
- Metryki DORA jako wskaźnik dojrzałości organizacji
- Platform Engineering: Internal Developer Platforms, golden paths, developer experience
- Trendy 2026: AI w operacjach, FinOps, GitOps

### 2. Konteneryzacja — od maszyn wirtualnych do WebAssembly
- Ewolucja wirtualizacji: VM → kontener → WASM
- Architektura kontenerów: namespaces, cgroups, union filesystem
- Dockerfile best practices: multi-stage builds, non-root users, minimalne obrazy
- Alternatywy Dockera: Podman, containerd, CRI-O
- Bezpieczeństwo kontenerów: skanowanie obrazów, runtime security, podpisywanie (Cosign)
- WebAssembly jako alternatywny runtime (WASI, Spin, Wasmtime)

### 3. Orkiestracja kontenerów — Kubernetes 2026
- Architektura Kubernetes: control plane, worker nodes, etcd
- Kluczowe obiekty: Pod, Deployment, Service, ConfigMap, Secret, Namespace
- Networking: CNI (Cilium), Network Policies, Gateway API
- Storage: PersistentVolumes, StorageClasses, StatefulSets
- Autoskalowanie: HPA, VPA, KEDA (event-driven), Karpenter
- Wzorce deploymentu: rolling update, blue-green, canary (Argo Rollouts)
- Service Mesh: Istio Ambient Mesh, mTLS, traffic management

### 4. Wprowadzenie do chmury obliczeniowej
- Definicja chmury (NIST), modele serwisowe: IaaS, PaaS, SaaS, FaaS
- Modele wdrożeniowe: public, private, hybrid, multi-cloud
- Porównanie dostawców: AWS, Azure, GCP — usługi, cennik, udziały rynkowe
- Kluczowe usługi: compute, storage, networking, bazy danych, serverless
- Modele rozliczeń: pay-as-you-go, reserved instances, spot instances, free tier
- Praktyczne aspekty: regiony, strefy dostępności, IAM, shared responsibility model

### 5. Infrastructure as Code — Terraform, OpenTofu, Pulumi
- Filozofia IaC: reproducibility, version control, drift detection
- Deklaratywne vs programowalne podejście do zarządzania infrastrukturą
- Terraform / OpenTofu: HCL, providers, modules, state management
- Pulumi: programowalne IaC (Python, TypeScript, Go)
- Terragrunt: zarządzanie wieloma środowiskami
- Ansible: configuration management vs provisioning
- GitOps: Git jako źródło prawdy, ArgoCD, FluxCD

### 6. CI/CD i automatyzacja procesów deweloperskich
- Pipeline CI/CD: build, test, lint, security scan, deploy
- Trunk-based development i feature flags
- Progressive delivery: canary, blue-green, ring-based deployment
- Metryki DORA w praktyce
- GitOps: push vs pull, ArgoCD jako operator GitOps
- AI-powered CI/CD: generowanie testów, automatyczne poprawki podatności

### 7. Monitorowanie i obserwowalność systemów rozproszonych
- Monitoring vs observability: "co się stało?" vs "dlaczego się stało?"
- Three Pillars: metrics, logs, traces
- Wzorce: RED method, USE method, SLI/SLO/SLA
- OpenTelemetry jako vendor-neutral standard
- Grafana LGTM stack (Loki, Grafana, Tempo, Mimir) vs ELK
- eBPF observability: Cilium Tetragon, Pixie
- Prometheus ecosystem: PromQL, AlertManager, remote write

### 8. Bezpieczeństwo oprogramowania — od kodu do łańcucha dostaw

#### Tur 1: DevSecOps
- Filozofia shift-left security: bezpieczeństwo na każdym etapie pipeline'u
- Narzędzia: SAST (Semgrep, CodeQL), DAST (OWASP ZAP), SCA (Snyk)
- Zarządzanie sekretami: HashiCorp Vault, Sealed Secrets, SOPS
- Container security: skanowanie obrazów, runtime protection (Falco)

#### Tur 2: Supply Chain Security
- Słynne ataki na łańcuch dostaw: SolarWinds, Log4Shell, XZ Utils
- SBOM (Software Bill of Materials): CycloneDX, SPDX, wymagania prawne (EU CRA)
- SLSA: poziomy bezpieczeństwa buildów (L1–L4)
- Podpisywanie artefaktów: Sigstore/Cosign, keyless signing
- Hermetic builds i reproducibility

### 9. Cloud-native architecture, FinOps i odporność
- 12-Factor App w 2026
- Serverless deep dive: FaaS, BaaS, cold start, anti-patterny, kiedy serverless vs K8s
- Multi-cloud strategies: portability, vendor lock-in
- FinOps: visibility kosztów, rightsizing, reserved/spot instances
- Backup i disaster recovery: 3-2-1 rule, Velero, RTO/RPO
- Chaos engineering: Litmus Chaos, GameDay, testowanie odporności w produkcji

### 10. AI/ML w DevOps i przyszłość systemów rozproszonych
- AI pair programming: GitHub Copilot, Claude Code, Cursor
- AI agents w development: automatyczna naprawa issue'ów, code review
- AIOps: anomaly detection, predictive alerting, root cause analysis, self-healing
- Platform Engineering i AI: automatyzacja self-service, golden paths
- Responsible AI: koszty inference, sustainability, bezpieczeństwo modeli

### 11. Compliance i ramy regulacyjne
- Krajobraz regulacyjny 2026: GDPR, EU AI Act, EU CRA, DORA, NIS2
- ISO/IEC 27001:2022 — System Zarządzania Bezpieczeństwem Informacji (ISMS)
- SOC 2: Trust Services Criteria, Type I/II, audyty
- GDPR: zasady, prawa podmiotów, Privacy by Design
- Porównanie frameworków: ISO 27001, SOC 2, GDPR, PCI-DSS, HIPAA
- Compliance w praktyce DevOps: Policy as Code (OPA, Kyverno), continuous compliance
- Cloud compliance: shared responsibility model, narzędzia dostawców

## Wymagania wstępne
- Podstawowa znajomość systemów Linux/Unix
- Zrozumienie koncepcji sieci komputerowych
- Podstawowa znajomość programowania (dowolny język)

## Ocena i wymagania
Przedmiot zaliczony jest kolokwium przeprowadzonym na zajęciach w laboratorium.
