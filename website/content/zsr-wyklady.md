+++
title = 'Zarządzanie Systemami Rozproszonymi - wykład'
date = 2024-10-03T22:21:06+02:00
draft = false
+++
Systemy Rozproszone i Chmurowe
Sala L128  
poniedziałki, 16:50 (45 min)  
Semestr zimowy 2025/26  

## Cele przedmiotu

### Cel główny
Zapoznanie studentów z nowoczesnymi praktykami zarządzania systemami rozproszonymi, ze szczególnym uwzględnieniem metodologii DevOps, konteneryzacji oraz zadań współczesnego administratora systemów.

### Cele szczegółowe
1. Zrozumienie fundamentów filozofii DevOps i jej wpływu na współczesne IT
2. Opanowanie koncepcji konteneryzacji i orkiestracji kontenerów
3. Poznanie nowoczesnych narzędzi do automatyzacji i zarządzania infrastrukturą
4. Zrozumienie znaczenia monitorowania i obserwabilności w systemach rozproszonych
5. Poznanie strategii backup i odzyskiwania danych w środowiskach chmurowych
6. Zrozumienie wyzwań bezpieczeństwa w architekturach rozproszonych

## Szczegółowy plan zajęć

### Sesja 1: Wprowadzenie do DevOps i współczesnego administrowania systemów 
**Cele edukacyjne:**
- Zrozumienie ewolucji ról administratora systemów
- Poznanie podstaw filozofii DevOps
- Identyfikacja kluczowych wyzwań współczesnego IT

**Tematyka:**
- Historia i ewolucja administracji systemów: od klasycznego sysadmina do DevOps engineera
- Podstawy filozofii DevOps: CALMS (Culture, Automation, Lean, Measurement, Sharing)
- Współczesne wyzwania: skalowanie, automatyzacja, bezpieczeństwo
- Trendy na 2025: AI/ML w operacjach, Platform Engineering, GitOps
- Rola administratora w organizacjach wielochmurowych
- Case study: transformacja cyfrowa w polskich przedsiębiorstwach

**Literatura:**
- "The Phoenix Project" - Kevin Kim, Gene Kim, George Spafford (wybrane rozdziały)
- Raporty State of DevOps 2024/2025

[slajdy](/jwozniak/lectures/zsr-1.pdf)

### Sesja 2: Konteneryzacja - fundamenty Docker i nowoczesne praktyki
**Cele edukacyjne:**
- Zrozumienie koncepcji konteneryzacji
- Poznanie najlepszych praktyk Docker w 2025
- Zrozumienie bezpieczeństwa kontenerów

**Tematyka:**
- Ewolucja wirtualizacji: od VM do kontenerów
- Architektura Docker: daemon, images, containers, registry
- Dockerfile best practices 2025: multi-stage builds, non-root users, minimal images
- Container security: scanning, trusted images, runtime security
- Docker Compose dla aplikacji wielokontenerowych
- Alternatywy dla Docker: Podman, containerd, CRI-O
- Trendy: WebAssembly jako przyszłość kontenerów

**Przypadki praktyczne:**
- Analiza Dockerfile dla aplikacji webowej
- Przegląd strategii bezpieczeństwa kontenerów w produkcji

### Sesja 3: Orkiestracja kontenerów - Kubernetes w praktyce
**Cele edukacyjne:**
- Zrozumienie architektury Kubernetes
- Poznanie kluczowych obiektów K8s
- Zrozumienie wyzwań administracji klastrów

**Tematyka:**
- Architektura Kubernetes: master/worker nodes, control plane
- Kluczowe obiekty: Pods, Services, Deployments, ConfigMaps, Secrets
- Networking w Kubernetes: CNI, Service Mesh, Ingress
- Storage: PersistentVolumes, StorageClasses
- Wzorce deployment: Rolling updates, Blue-Green, Canary
- Kubernetes management: Helm, Kustomize, Operators
- Managed Kubernetes: EKS, GKE, AKS - porównanie i wybór

**Case study:**
- Migracja aplikacji monolitycznej do architektury mikroserwisów na K8s

### Sesja 4: Zarządzanie infrastrukturą jako kod (Infrastructure as Code)
**Cele edukacyjne:**
- Zrozumienie koncepcji IaC
- Poznanie narzędzi do automatyzacji infrastruktury
- Zrozumienie wzorców zarządzania konfiguracją

**Tematyka:**
- Filozofia Infrastructure as Code: korzyści, wyzwania, best practices
- Terraform: deklaratywne zarządzanie infrastrukturą multicloud
- Ansible: automatyzacja konfiguracji i deployment
- GitOps: Git jako źródło prawdy dla infrastruktury
- Pulumi vs Terraform: porównanie nowoczesnych rozwiązań IaC
- Configuration Management: drift detection, compliance
- Immutable Infrastructure vs Configuration Management

**Przykłady praktyczne:**
- Template Terraform dla klastra Kubernetes
- Ansible playbook dla konfiguracji serwerów aplikacyjnych

### Sesja 5: CI/CD i automatyzacja procesów deweloperskich
**Cele edukacyjne:**
- Zrozumienie pipeline CI/CD
- Poznanie nowoczesnych narzędzi automatyzacji
- Zrozumienie wzorców deployment

**Tematyka:**
- Continuous Integration: automated testing, code quality, security scanning
- Continuous Deployment vs Continuous Delivery
- Jenkins vs GitHub Actions vs GitLab CI: porównanie platform
- Pipeline as Code: Jenkinsfile, GitHub Workflows, GitLab CI YAML
- Artifact management: container registries, package repositories
- Feature flags i progressive delivery
- Monitoring i observability w pipeline

**Analiza przypadków:**
- Design pipeline CI/CD dla aplikacji e-commerce
- Strategies for zero-downtime deployments

### Sesja 6: Monitorowanie i obserwabilność systemów rozproszonych
**Cele edukacyjne:**
- Zrozumienie różnicy między monitoring a observability
- Poznanie Three Pillars of Observability
- Zrozumienie nowoczesnych narzędzi monitorowania

**Tematyka:**
- Three Pillars of Observability: metrics, logs, traces
- Prometheus ecosystem: Prometheus, Grafana, AlertManager
- ELK/EFK Stack: Elasticsearch, Logstash/Fluentd, Kibana
- Distributed tracing: Jaeger, Zipkin, OpenTelemetry
- AIOps: machine learning w monitorowaniu
- SRE practices: SLI, SLO, error budgets
- Chaos Engineering: proaktywne testowanie niezawodności

**Praktyczne zagadnienia:**
- Design monitoring strategy dla systemu e-commerce
- Incident response i postmortem analysis

### Sesja 7: Bezpieczeństwo i DevSecOps
**Cele edukacyjne:**
- Zrozumienie koncepcji "shift-left security"
- Poznanie narzędzi do automatyzacji bezpieczeństwa
- Zrozumienie compliance w środowiskach chmurowych

**Tematyka:**
- DevSecOps: integracja bezpieczeństwa w pipeline CI/CD
- Shift-left security: security scanning w development
- Container security: image scanning, runtime protection
- Secrets management: HashiCorp Vault, cloud-native solutions
- Network security: Zero Trust, service mesh security
- Compliance automation: GDPR, SOC2, PCI-DSS
- Threat modeling dla aplikacji rozproszonej

**Case studies:**
- Implementacja DevSecOps w organizacji finansowej
- Response na incident bezpieczeństwa w środowisku Kubernetes

### Sesja 8: Backup i strategie odzyskiwania danych (1,5h)
**Cele edukacyjne:**
- Zrozumienie nowoczesnych strategii backup
- Poznanie cloud-native backup solutions
- Zrozumienie disaster recovery planning

**Tematyka:**
- Backup strategies: 3-2-1 rule w erze chmury
- Cloud-native backup: snapshots, cross-region replication
- Kubernetes backup: Velero, Kasten K10
- Database backup w środowiskach rozproszonych
- Disaster Recovery: RTO, RPO, business continuity
- Backup automation i orchestration
- Testing backup i disaster recovery scenarios

**Praktyczne aspekty:**
- Design backup strategy dla systemu bankowego
- Disaster recovery plan dla multi-cloud deployment

### Sesja 9: Chmura i strategie skalowania systemów
**Cele edukacyjne:**
- Zrozumienie wzorców cloud-native architecture
- Poznanie strategii skalowania
- Zrozumienie multi-cloud i hybrid cloud

**Tematyka:**
- Cloud-native architecture patterns: 12-factor app, microservices
- Auto-scaling: HPA, VPA, cluster autoscaling
- Serverless computing: Functions as a Service, event-driven architecture
- Multi-cloud strategies: vendor lock-in avoidance, disaster recovery
- Edge computing: CDN, edge functions, IoT
- Cost optimization w chmurze
- FinOps: financial operations dla cloud resources

**Analiza:**
- Migration strategy z on-premise do chmury
- Cost optimization dla startup vs enterprise

### Sesja 10: Przyszłość administracji - AI/ML w DevOps i emerging trends
**Cele edukacyjne:**
- Zrozumienie wpływu AI/ML na operations
- Poznanie emerging technologies
- Przygotowanie na przyszłe wyzwania

**Tematyka:**
- AIOps: machine learning dla IT operations
- Generative AI w DevOps: code generation, documentation, troubleshooting
- Platform Engineering: internal developer platforms
- Autonomous operations: self-healing systems
- Quantum computing impact na cybersecurity
- Sustainability w IT: green computing, carbon footprint
- WebAssembly: przyszłość konteneryzacji

**Podsumowanie i dyskusja:**
- Kariera w DevOps/SRE: ścieżki rozwoju
- Certyfikacje i dalsze uczenie się
- Q&A i dyskusja o przyszłości branży

## Wymagania wstępne
- Podstawowa znajomość systemów Linux/Unix
- Zrozumienie koncepcji sieci komputerowych
- Podstawowa znajomość programowania (dowolny język)
- Znajomość podstaw architektury systemów rozproszonych

## Ocena i wymagania
Przedmiot zaliczony jest kolokwium przeprowadzonym na zajęciach w laboratorium.

## Literatura i zasoby

### Literatura podstawowa:
1. "The DevOps Handbook" - Gene Kim, Jez Humble, Patrick Debois, John Willis
2. "Site Reliability Engineering" - Google SRE Team
3. "Kubernetes: Up and Running" - Kelsey Hightower, Brendan Burns, Joe Beda
4. "Infrastructure as Code" - Kief Morris

### Literatura uzupełniająca:
1. "The Phoenix Project" - Gene Kim, Kevin Behr, George Spafford
2. "Accelerate" - Nicole Forsgren, Jez Humble, Gene Kim
3. "Docker Deep Dive" - Nigel Poulton
4. "Terraform: Up and Running" - Yevgeniy Brikman

### Zasoby online:
- Kubernetes Documentation (kubernetes.io)
- Docker Documentation (docs.docker.com)
- AWS/Azure/GCP Documentation
- CNCF Landscape (landscape.cncf.io)
- State of DevOps Reports (puppet.com, google.com)
