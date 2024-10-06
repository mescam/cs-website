+++
title = 'Zarządzanie Systemami Rozproszonymi - wykład'
date = 2024-10-03T22:21:06+02:00
draft = false
+++

Semestr zimowy 2024/25  
Sala L0.2.9  
poniedziałki, 16:50  

### Plan wykładów

1. #### Wprowadzenie do DevOps i systemów rozproszonych
   [prezentacja](/jwozniak/lectures/0-intro.pdf]    
   - Filozofia DevOps
   - Zasady systemów rozproszonych
   - Automatyzacja i ciągłe dostarczanie w DevOps
   - Przegląd narzędzi: Ansible, Puppet, Chef
   - Zarządzanie konfiguracją w środowiskach lokalnych i chmurowych  

2. #### CI/CD i konteneryzacja
   - Wprowadzenie do CI/CD: Jenkins, GitLab CI/CD
   - Pipeline CI/CD: budowanie, testowanie, wdrażanie
   - Docker: konteneryzacja aplikacji, tworzenie obrazów, Docker Compose
   - Optymalizacja i bezpieczeństwo obrazów Docker
   - Tworzenie wielokontenerowych aplikacji

3. #### Kubernetes: Orkiestracja i zarządzanie kontenerami
   - Wprowadzenie do Kubernetes: Podstawy i komponenty (Pod, Node, Cluster)
   - Skalowanie aplikacji, HPA i VPA
   - Deployment, StatefulSets, DaemonSets
   - Zaawansowane zarządzanie Kubernetes: Namespaces, QoS, zasoby

4. #### Monitorowanie i zarządzanie logami w systemach rozproszonych
   - Monitorowanie aplikacji i infrastruktury: Prometheus, Grafana
   - Tworzenie i zarządzanie metrykami oraz dashboardami
   - Zarządzanie logami: ELK Stack, Fluentd
   - Centralizacja logów i analiza

5. #### Infrastructure as Code (IaC) i automatyzacja z Terraform
   - Wprowadzenie do IaC: Koncepcje i korzyści
   - Terraform: tworzenie infrastruktury chmurowej (AWS, Azure, Google Cloud)
   - Modułowość w Terraform: Moduły wielokrotnego użytku, stan infrastruktury
   - Automatyzacja zarządzania infrastrukturą z Terraform Cloud

6. #### GitOps: Deklaratywne zarządzanie infrastrukturą
   - Wprowadzenie do GitOps: zasady i korzyści
   - Narzędzia GitOps: ArgoCD, Flux
   - Automatyzacja wdrożeń w Kubernetes za pomocą GitOps
   - Przykłady wdrożeń i zarządzania zmianami w produkcji

7. #### Bezpieczeństwo, High Availability i Disaster Recovery
   - Bezpieczeństwo w Kubernetes: RBAC, Network Policies
   - Skany bezpieczeństwa kontenerów (Trivy)
   - Tworzenie systemów o wysokiej dostępności (HA) w Kubernetes
   - Disaster Recovery: strategie backupu i przywracania w chmurze
