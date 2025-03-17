+++
title = 'Projektowanie Systemów Rozproszonych - wykład'
date = 2025-01-25T21:37:00+02:00
draft = false
+++

Przedmiot przedstawia zasady projektowania i wdrażania nowoczesnych architektur rozproszonych, obejmujących rozwiązania monolityczne, mikroserwisowe i chmurowe. Obejmuje kluczowe zagadnienia skalowania, bezpieczeństwa, zarządzania danymi oraz przepływów komunikacji w środowiskach wieloserwerowych. Uwzględnione są strategie migracji do mikroserwisów, narzędzia konteneryzacji oraz integracja podejść PaaS i FaaS. Końcowe wykłady poruszają najnowsze trendy, takie jak serverless, multi-cloud czy edge computing, stanowiąc podsumowanie i wskazując perspektywy rozwoju w dziedzinie systemów rozproszonych.

### Informacje

Semestr letni 2024/25  

### Plan wykładów

#### Wykład 1: Wprowadzenie do Systemów Rozproszonych

* Definicja i przykłady – co oznacza „rozproszony”, zastosowania w praktyce.
* Historia i ewolucja – od scentralizowanych architektur do mikroserwisów.
* Kluczowe wyzwania – skalowanie, spójność danych, zarządzanie stanem.
* Modele architektoniczne – przegląd typowych modeli (client-server, peer-to-peer, event-driven).
* Zarys dalszych wykładów – wprowadzenie do tematyki migracji, chmury i serverless.

#### Wykład 2: Komponenty i Architektura Systemów Rozproszonych

* Warstwy systemu – prezentacji, logiki biznesowej, danych.
* Wzorce komunikacji – synchroniczne (HTTP/REST, gRPC) i asynchroniczne (kolejki, publish/subscribe).
* Service registry i discovery – podstawowe mechanizmy.
* Kluczowe pojęcia – opóźnienie, przepustowość, high availability.
* Studium przypadku – przykładowy system rozproszony w organizacji.

[slajdy](/jwozniak/lectures/psr-lecture-2.pdf)

#### Wykład 3: Komunikacja i Protokoły w Systemach Rozproszonych

* Protokoły internetowe – TCP, UDP, HTTP, HTTPS.
* Synchroniczne vs. asynchroniczne – omówienie zalet i wad.
* Wzorce integracji – event bus, message broker, publish/subscribe.
* API Gateway – rola w systemach rozproszonych, load balancing, bezpieczeństwo.
* Przykładowe narzędzia – RabbitMQ, Kafka, ZeroMQ, NATS.

#### Wykład 4: Skalowanie, Replikacja i Równoważenie Obciążenia

* Skalowanie pionowe i poziome – definicje, kiedy stosować.
* Replikacja danych – strategie i rodzaje.
* Load balancing – Round Robin, Weighted, ip hash, session affinity.
* Projektowanie pod kątem skalowalności – sharding, partitioning.
* Narzędzia – Nginx, HAProxy, Envoy.

#### Wykład 5: Planowanie Obciążenia i Modelowanie Przepływów

* Znaczenie przewidywania obciążenia – jak uniknąć przeciążeń, dostosować zasoby i koszty.
* Modelowanie przepływów komunikacji – diagramy zależności, identyfikacja bottlenecków.
* Testy wydajności – narzędzia (JMeter, Gatling, Locust) i metryki (latencja, throughput, p95/p99).
* Scenariusze skokowego wzrostu ruchu – planowanie peak times, bursty, trendy sezonowe.
* Praktyka w środowisku rozproszonym – uwzględnianie kolejek, load balancerów i architektur event-driven.

#### Wykład 6: Wzorce Architektoniczne w Systemach Rozproszonych

* Monolit vs. mikroserwisy – porównanie.
* Architektura zdarzeniowa – event-driven, CQRS, event sourcing.
* Wzorzec Sagi – zarządzanie transakcjami rozproszonymi.
* Orkiestracja vs. choreografia – różnice w projektowaniu przepływów.
* Wzorce integracji – Strangler Pattern, Anti-Corruption Layer.

#### Wykład 7: Monolity, Mikroserwisy i Modułowe Monolity

* Klasyczny monolit – zalety i wyzwania.
* Modułowy monolit – główne założenia.
* Mikroserwisy – cechy, korzyści i trudności.
* Współpraca usług – synchronicznie (REST/gRPC) i asynchronicznie (eventy/kolejki).
* Narzędzia wdrożeniowe – konteneryzacja, orkiestracja.

#### Wykład 8: Strategie Migracji z Monolitu do Mikroserwisów

* Diagnoza istniejącego systemu – identyfikacja granic kontekstów.
* Podejście iteracyjne – wyodrębnianie serwisów krok po kroku.
* Techniki migracji – Strangler Fig, re-platforming, refactoring.
* Obszary ryzyka – spójność danych, zmiany w komunikacji, zarządzanie konfiguracją.
* Case study – przykładowy plan migracji w średniej wielkości organizacji.

#### Wykład 9: Orkiestracja i Choreografia

* Zalety systemów orkiestrujących – koordynacja przepływu zdarzeń.
* Choreografia – autonomiczne serwisy współpracujące przez zdarzenia.
* Kiedy wybrać orkiestrację, a kiedy choreografię.
* Narzędzia – BPMN, Camunda, Zeebe, platformy event-driven (Kafka).
* Projektowanie przepływów – praktyczne przykłady.

#### Wykład 10: Bazy Danych w Systemach Rozproszonych

* Przegląd typów baz danych – relacyjne, NoSQL, NewSQL.
* Strategie rozproszenia – partitioning, sharding, replikacja.
* Spójność – ACID vs. BASE, eventual consistency.
* Transakcje rozproszone – 2PC, Sagi.
* Przykłady – Cassandra, MongoDB, CockroachDB.

#### Wykład 11: Bezpieczeństwo i Autoryzacja

* Podstawy bezpieczeństwa – szyfrowanie, TLS/SSL, API security.
* Uwierzytelnienie i autoryzacja – OAuth 2.0, JWT, OpenID Connect.
* IAM, SSO – zarządzanie tożsamością.
* Dostęp i uprawnienia – RBAC, ABAC.
* Monitorowanie incydentów – narzędzia WAF, SIEM.

#### Wykład 12: Techniki i Narzędzia do Projektowania i Wdrażania

* Konteneryzacja – Docker, Podman.
* Orkiestracja – Kubernetes, Docker Swarm.
* Infrastruktura jako Kod (IaC) – Terraform, Ansible.
* Architektura Cloud-native – 12-factor app.
* CI/CD (zarys) – narzędzia (Jenkins, GitLab CI, GitHub Actions).

#### Wykład 13: Wprowadzenie do Chmur Publicznych i Modeli Usług

* Rodzaje chmur – publiczne, prywatne, hybrydowe.
* Modele usług – IaaS, PaaS, SaaS, FaaS.
* Dostawcy chmurowi – AWS, Azure, GCP.
* Podstawowe usługi w chmurze – compute, storage, networking.
* Aspekty kosztowe – pay-per-use, elastyczne skalowanie.

#### Wykład 14: Serverless, PaaS i FaaS

* Koncepcja serverless – zalety i ograniczenia.
* Platform as a Service – Heroku, AWS Elastic Beanstalk.
* Function as a Service – AWS Lambda, Azure Functions, Google Cloud Functions.
* Architektura bezserwerowa – event-driven, stateless.
* Praktyczne przykłady – koszty, monitoring, cold starts.

##### Wykład 15: Trendy, Perspektywy i Podsumowanie

* Aktualne trendy – edge computing, multi-cloud, service mesh.
* Nowości – WebAssembly (wasm), rozproszone przetwarzanie AI/ML.
* Zarys rozwoju zawodowego – rola architekta systemów rozproszonych.
* Podsumowanie przedmiotu – kluczowe wnioski, powtórka.
* Sesja pytań i odpowiedzi – dyskusja końcowa.
