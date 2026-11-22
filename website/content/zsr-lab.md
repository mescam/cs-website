+++
title = 'Zarządzanie Systemami Rozproszonymi - laboratorium'
date = 2024-10-03T22:21:13+02:00
draft = false
+++

### Informacje

Semestr zimowy 2026/27  
Laboratorium 1.6.16  
poniedziałki, od razu po wykładzie

### Zaliczenie

Przedmiot zaliczony jest kolokwium przeprowadzonym na zajęciach w laboratorium.

### Plan laboratoriów

Zajęcia prowadzone są w trzech blokach. Każdy blok ma własny skrypt i materiały, które należy zachować w swoim repozytorium.

#### 1. Ansible: automatyzacja konfiguracji
  - **Wymagania**: VirtualBox, Vagrant, podstawy terminala i SSH
  - **Zakres**:
    - Inventory i playbook konfigurujący dwa serwery WWW
    - Zmienne, szablony i handlery
    - Idempotencja i sprawdzanie zmian
  - [skrypt dla studentów (PDF)](/jwozniak/labs/0-ansible.pdf)
  - [materiały środowiska (ZIP)](/jwozniak/labs/ansible-materialy.zip)

#### 2. Kontenery aplikacyjne: Docker, Kubernetes i GitOps
  - **Wymagania**: Docker, Minikube, kubectl i Git; dodatkowe spotkania: Helm
  - **Zakres**:
    - Dockerfile, obrazy, sieć kontenerów i wolumeny
    - Uruchomienie Redmine z PostgreSQL, a następnie wdrożenie Flaska w Kubernetesie
    - Pod, Deployment, Service, skalowanie, aktualizacje i diagnostyka
    - Sondy zdrowia, ConfigMap, Secret, StatefulSet i PVC
    - Job, CronJob, sidecar, SecurityContext i NetworkPolicy
    - Gateway API z Traefikiem
    - Prometheus, Grafana i Alertmanager: ruch, błędy i p95 z histogramu
    - Alert z mailem, ślad i log tej samej operacji, diagnoza przypadku
    - GitOps z Argo CD: repozytorium jako źródło prawdy, synchronizacja, samonaprawa, prune i rollback
  - [skrypt dla studentów (PDF)](/jwozniak/labs/1-docker.pdf)
  - [materiały startowe (ZIP)](/jwozniak/labs/docker-materialy.zip)
  - Materiały uzupełniające: [Cert-Manager](/jwozniak/labs/5b-certbot.pdf), [Service Mesh z Istio](/jwozniak/labs/6-servicemesh.pdf)

#### 3. Chmura publiczna: infrastruktura i wdrożenia
  - **Wymagania**: subskrypcja Azure for Students, Terraform, Git
  - **Zakres**:
    - Wprowadzenie do chmury publicznej i Terraform: zasoby, zmienne, plan
    - Moduły, stan zdalny i praca zespołowa
    - GitOps z ArgoCD
    - AKS i podsumowanie: infrastruktura, klaster i wdrożenie aplikacji
  - [Terraform: tworzenie infrastruktury chmurowej](/jwozniak/labs/7-azuretf.pdf)
  - [Terraform: moduły, zmienne i stan zdalny](/jwozniak/labs/8-terraform.pdf)
  - [GitOps z ArgoCD](/jwozniak/labs/5-gitops.pdf)
  - [AKS i Terraform: podsumowanie](/jwozniak/labs/9-final.pdf)
