+++
title = 'Projektowanie Systemów Rozproszonych - wykład'
date = 2025-01-25T21:37:00+02:00
draft = false
+++

Przedmiot koncentruje się na **projektowaniu aplikacji rozproszonych i chmurowych** — na decyzjach architektonicznych, wzorcach komunikacji, zarządzaniu danymi i niezawodnością, które inżynier podejmuje _zanim_ system trafi do pipeline'u CI/CD. Każdy wykład łączy fundamenty (papery, modele) z praktyką (case study z przemysłu, blogi inżynierskie) i zawiera pytanie do dyskusji ze studentami.

### Informacje

Semestr letni 2025/26  
10 spotkań × 1.5h  

Kurs zakłada znajomość podstaw z ZSR (Docker, K8s, CI/CD, cloud basics).

### Literatura podstawowa

1. M. Kleppmann — *Designing Data-Intensive Applications* (O'Reilly, 2017)
2. S. Newman — *Building Microservices*, 2nd ed. (O'Reilly, 2021)
3. C. Richardson — *Microservices Patterns* (Manning, 2018)
4. A. Xu — *System Design Interview* Vol. 1 (2020) & Vol. 2 (2022)

### Plan wykładów

#### Wykład 1: Anatomia systemu rozproszonego — od wymagań do architektury

* Rola architekta vs rola operatora — co znaczy „projektować" system rozproszony
* Wymagania funkcjonalne vs niefunkcjonalne (reliability, scalability, maintainability)
* Back-of-the-envelope estimation — szacowanie obciążenia, przepustowości, storage
* Przegląd modeli architektonicznych: client-server, peer-to-peer, event-driven, hybrid
* SLA / SLO / SLI — definiowanie kontraktu niezawodności
* Skalowanie: pionowe vs poziome, stateless vs stateful
* ☁️ Estymacja kosztów chmurowych (koszt/request, koszt/GB), managed services jako sposób na skalowanie

**Case study:** „Scale From Zero To Millions Of Users" (A. Xu, rozdz. 1)

[slajdy](/jwozniak/lectures/psr-w01.pdf)

#### Wykład 2: Style architektoniczne — monolit, mikroserwisy, modularny monolit

* Monolit — kiedy wystarczy (Majestic Monolith — DHH/Basecamp)
* Modularny monolit — granice modułów bez kosztów sieciowych (Shopify)
* Mikroserwisy — korzyści, koszty, kiedy wydzielać
* Domain-Driven Design — Bounded Contexts jako linie podziału serwisów
* Distributed Monolith — anti-pattern
* ☁️ Cloud-native vs cloud-hosted — 12-Factor App, kontenery i PaaS (Cloud Run, App Service, ECS)

**Case study:** Segment.io — od monolitu do ~100 mikroserwisów i z powrotem

[slajdy](/jwozniak/lectures/psr-w02.pdf)

#### Wykład 3: Komunikacja w systemach rozproszonych

* Komunikacja synchroniczna: REST, gRPC, GraphQL — kiedy co wybrać
* Komunikacja asynchroniczna: message brokers (Kafka, RabbitMQ, NATS)
* Wzorce: request-response, fire-and-forget, event notification
* API Gateway — routing, rate limiting, uwierzytelnianie na brzegu
* Backend for Frontend (BFF)
* API versioning, schema evolution, backward/forward compatibility
* Idempotencja operacji — klucze idempotentności, retry safety
* ☁️ Managed brokers (SQS/SNS, Google Pub/Sub, Azure Service Bus), managed API Gateway

**Case study:** „Design a Chat System" (A. Xu, rozdz. 12) — polling, long-polling, WebSocket

[slajdy](/jwozniak/lectures/psr-w03.pdf)

#### Wykład 4: Wzorce architektoniczne — Event-Driven Architecture, CQRS, Event Sourcing

* Event-Driven Architecture — decoupling producentów i konsumentów
* Event notification vs Event-carried state transfer vs Event sourcing
* CQRS — oddzielne modele odczytu i zapisu
* Event Sourcing — log zdarzeń jako źródło prawdy, snapshoty
* Orkiestracja vs Choreografia — Saga Orchestrator vs autonomiczne serwisy
* Wzorzec Sagi — choreograficzna vs orkiestracyjna, kompensacje
* ☁️ Managed event services (EventBridge, Cloud Events), managed workflow (AWS Step Functions, GCP Workflows)

**Case study:** System zamówień — rezerwacja stocku → płatność → wysyłka. 2PC vs saga.

[slajdy](/jwozniak/lectures/psr-w04.pdf)

#### Wykład 5: Dane w systemach rozproszonych — strategie, replikacja, partycjonowanie

* Database per Service — konsekwencje projektowe
* Wybór bazy danych pod przypadek użycia (PostgreSQL, MongoDB, Cassandra, Redis, DynamoDB)
* Replikacja — leader-follower, multi-leader, leaderless (quorum)
* Partycjonowanie — range-based, hash-based, consistent hashing
* Spójność — ACID vs BASE, eventual consistency, CAP/PACELC
* Transakcje rozproszone — 2PC, Saga
* Change Data Capture (CDC) — Debezium, Kafka Connect
* ☁️ Managed databases (RDS, Cloud SQL, DynamoDB, CosmosDB), managed replikacja i sharding

**Case study:** „Design a Key-Value Store" (A. Xu, rozdz. 6) — consistent hashing, quorum, vector clocks

#### Wykład 6: Odporność i niezawodność — projektowanie na awarie

* Fallacies of Distributed Computing
* Design for Failure — awaria jako norma
* Wzorce: Circuit Breaker, Bulkhead, Retry with backoff + jitter, Timeout, Dead Letter Queue, Graceful degradation
* Rate limiting — Token Bucket, Sliding Window, rozproszony rate limiter
* Load balancing — algorytmy, health checks
* Autoskalowanie — HPA, VPA, KEDA
* Chaos Engineering — Netflix Simian Army, GameDay
* ☁️ Cloud resilience (AZ/Region failover, global load balancer), AWS Fault Injection Simulator

**Case study:** „Design a Rate Limiter" (A. Xu, rozdz. 4) — Token Bucket vs Sliding Window, Redis

#### Wykład 7: Migracja i ewolucja architektury

* Diagnoza istniejącego systemu — identyfikacja bounded contexts w monolicie
* Strangler Fig Pattern, Branch by Abstraction, Anti-Corruption Layer, Parallel Run
* Zarządzanie danymi w trakcie migracji — dual writes, CDC
* Feature flags — stopniowe wdrażanie zmian
* Migracja chmurowa — 6 R-ów migracji do chmury (AWS)

**Case study:** Monzo Bank — od monolitu do 2000+ mikroserwisów

#### Wykład 8: Przetwarzanie danych w skali — batch, streaming, pipelines

* Batch processing — MapReduce, Apache Spark, dbt
* Stream processing — Kafka Streams, Apache Flink
* Kafka jako centralny szkielet danych
* Lambda vs Kappa Architecture
* Change Data Capture w praktyce — Debezium + Kafka Connect
* Real-time analytics — ClickHouse, Apache Druid, Apache Pinot
* ETL vs ELT
* ☁️ Managed streaming (Kinesis, Dataflow), managed OLAP (BigQuery, Redshift), serverless ETL (Glue)

**Case study:** „Design a News Feed System" (A. Xu, rozdz. 11) — fan-out on write vs read

#### Wykład 9: Serverless, FaaS i architektura na brzegu

* Koncepcja serverless — „bez zarządzania serwerem", nie „bez serwera"
* FaaS — AWS Lambda, Azure Functions, Google Cloud Functions, cold starts
* Event-driven serverless — SQS, EventBridge, API Gateway
* Serverless poza FaaS — DynamoDB, Aurora Serverless, Fargate, Cloud Run
* Ograniczenia — vendor lock-in, debugowanie, koszty przy stałym ruchu
* Edge computing — Cloudflare Workers, Lambda@Edge, Vercel Edge Functions
* Multi-cloud i hybrid-cloud
* WebAssembly na serwerze — Spin, Fermyon
* ☁️ Porównanie kosztów: Lambda vs Fargate vs ECS vs EC2

**Case study:** „Design Google Drive" (A. Xu, rozdz. 15) — Lambda + S3 + SQS + DynamoDB

#### Wykład 10: Obserwowalność, bezpieczeństwo i przyszłość systemów rozproszonych

* Projektowanie pod obserwowalność — structured logging, correlation IDs, OpenTelemetry
* Distributed tracing — Jaeger, W3C Trace Context
* Metryki biznesowe vs techniczne — RED method (Rate, Errors, Duration)
* Zero Trust Architecture
* Uwierzytelnianie/autoryzacja w mikroserwisach — OAuth 2.0, JWT, mTLS, service mesh
* Zarządzanie sekretami — Vault, AWS Secrets Manager
* AI/ML w systemach rozproszonych — serving models at scale
* Platform Engineering — Backstage, Internal Developer Platforms
* ☁️ AWS Well-Architected Framework, GCP Architecture Center, FinOps

**Case study:** „Design YouTube" (A. Xu, rozdz. 14) — pełna analiza end-to-end łącząca wszystkie wykłady
