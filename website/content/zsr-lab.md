+++
title = 'Zarządzanie Systemami Rozproszonymi - laboratorium'
date = 2024-10-03T22:21:13+02:00
draft = false
+++

### Informacje

Semestr zimowy 2024/25  
Laboratorium 1.6.16  
poniedziałki, 18:15

### Zaliczenie

Zaliczenie wykładu i laboratoriów odbędzie się 27 stycznia na wykładzie (według planu zajęć). 

### Plan laboratoriów

1. #### Ansible: Automatyzacja konfiguracji
  - **Wymagania**: Ansible
  - **Zadania**:
    - Instalacja i konfiguracja Ansible
    - Tworzenie i uruchamianie playbooków
    - Automatyzacja konfiguracji serwerów
  - [skrypt](/jwozniak/labs/0-ansible.pdf)  

2. #### Docker: Konteneryzacja aplikacji
  - **Wymagania**: Docker
  - **Zadania**:
    - Tworzenie obrazów Docker
    - Uruchamianie i zarządzanie kontenerami
    - Tworzenie aplikacji wielokontenerowych
  - [skrypt](/jwozniak/labs/1-docker.pdf)

3. #### Kubernetes: Tworzenie klastra i skalowanie
  - **Wymagania**: Kubernetes (Minikube lub chmura)
  - **Zadania**:
    - Instalacja Kubernetes
    - Pod, Deployment, Service
    - PersistentVolume i PVC
    - Secrets i ConfigMaps
    - HPA
  - [skrypt](/jwozniak/labs/2-kubernetes.pdf)

4. #### Kubernetes: LivenessProbe, StatefulSet i Ingress
  - **Wymagania**: Kubernetes (minikube lub chmura)
  - **Zadania**:
    - Deployment nginx z livenessProbe
    - Baza danych przy użyciu StatefulSet
    - Konfiguracja Ingress na NGINX
  - [skrypt](/jwozniak/labs/3-kubernetes-2.pdf)

5. #### Monitorowanie z Prometheus i Grafana
  - **Wymagania**: Prometheus, Grafana
  - **Zadania**:
    - Konfiguracja Prometheus
    - Zbieranie metryk z aplikacji
    - Tworzenie dashboardów monitorujących w Grafana
  - [skrypt](/jwozniak/labs/4-monitoring.pdf)

6. #### GitOps z ArgoCD
  - **Wymagania**: Kubernetes, ArgoCD
  - **Zadania**:
    - Konfiguracja GitOps za pomocą ArgoCD
    - Automatyzacja wdrożeń aplikacji Kubernetes
  - [skrypt](/jwozniak/labs/5-gitops.pdf)

7. #### Service Mesh z Istio
  - **Wymagania**: Kubernetes, Istio
  - **Zadania**:
    - Instalacja i konfiguracja Istio
    - Monitorowanie ruchu sieciowego
    - Konfiguracja Ingress i Egress Gateway
  - [skrypt](/jwozniak/labs/6-servicemesh.pdf)

8. #### Terraform: Tworzenie infrastruktury chmurowej
  - **Wymagania**: Terraform, AWS/Azure/GCP
  - **Zadania**:
    - Wprowadzenie do chmury Microsoft Azure
    - Tworzenie prostych zasobów chmurowych (np. instancje EC2)
    - Automatyzacja zarządzania infrastrukturą
  - [skrypt](/jwozniak/labs/7-azuretf.pdf)

9. #### Terraform: moduły, zmienne i stan zdalny
  - **Wymagania**: Terraform, Microsoft Azure
  - **Zadania**:
    - Tworzenie modułów w Terraform
    - Użycie stanu zdalnego
    - Napisanie modułu maszyny wirtualnej
    - Stworzenie bazy danych
  - [skrypt](/jwozniak/labs/8-terraform.pdf)

10. #### AKS i Terraform - podsumowanie
  - **Wymagania**: Terraform, Microsoft Azure, Kubernetes
  - **Zadania**:
    - Stworzenie infrastruktury w Microsoft Azure
    - Konfiguracja klastra Kubernetes
    - Wystawienie aplikacji na świat
    - Zapewnienie ciągłego wdrażania
  - [skrypt](/jwozniak/labs/9-final.pdf)
