#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Kubernetes w eksploatacji", subtitle: [Sondy, zasoby, skalowanie i trwały magazyn], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Trzy sondy, trzy decyzje])[
#data-table(3,
[Sonda],
[Niepowodzenie po progu],
[Przykład],
[startup],
[Restart kontenera],
[Długa inicjalizacja cache],
[readiness],
[Pod niegotowy do zwykłego ruchu Service],
[API jeszcze nie obsługuje żądań],
[liveness],
[Restart kontenera],
[Trwale zablokowana pętla procesu],
)
- Do sukcesu startup pozostałe sondy są wstrzymane.
- Readiness nie zatrzymuje automatycznie odbioru wiadomości przez workera.
#src[#link("https://kubernetes.io/docs/concepts/workloads/pods/probes/")[Kubernetes — Probes]]
]
#slide(title: [Sondy HTTP: fragment kontenera])[
#codebox[
```yaml
ports: [{containerPort: 8080}]
startupProbe:
  httpGet: {path: /startup, port: 8080}
  periodSeconds: 5
  failureThreshold: 24
readinessProbe:
  httpGet: {path: /ready, port: 8080}
  periodSeconds: 5
  failureThreshold: 2
livenessProbe:
  httpGet: {path: /live, port: 8080}
  periodSeconds: 10
  failureThreshold: 3
```
]
#sm[Około 120 s budżetu startup. Rzeczywiste czasy zależą również od harmonogramu sond i timeoutów.]
]
#slide(title: [Awaria bazy a burza restartów])[
#flow[Baza niedostępna][/live sprawdza bazę][Restart wszystkich API]
- Restart API nie przywraca bazy; usuwa rozgrzane połączenia i cache.
- Liveness: warunek, którego naprawą rzeczywiście może być restart procesu.
- Readiness: zdolność do obsługi ruchu; zależności sprawdzane świadomie.
#exblock[API z cache][Część odczytów może działać mimo awarii bazy. Jedna wspólna sonda nie opisuje wszystkich tras.]
]
#slide(title: [Requests i limits])[
#codebox[
```yaml
resources:
  requests: {cpu: "250m", memory: "128Mi"}
  limits:   {cpu: "500m", memory: "256Mi"}
```
]
#data-table(3,
[Pole],
[Znaczenie],
[Obserwacja],
[CPU request],
[Wejście schedulera; udział przy konkurencji],
[Nie jest limitem 250m],
[CPU limit],
[Ograniczanie czasu CPU],
[Throttling, wzrost opóźnień],
[Memory limit],
[Granica pamięci kontenera],
[Możliwy OOM kill],
)
#src[#link("https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/")[Kubernetes — Resource management]]
]
#slide(title: [HPA: obliczenie liczby replik])[
#defblock[Uproszczony model][Nowe repliki = zaokrąglenie w górę(aktualne repliki × metryka / cel).]
- 3 Pody, każdy request CPU = 200m; średnie użycie = 160m.
- Wykorzystanie względem request = 80%; cel HPA = 50%.
- Nowa liczba: ceil(3 × 80 / 50) = *5*.
- Założenie: kompletne metryki, gotowe Pody, brak innych ograniczeń.
#src[#link("https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/")[Kubernetes — HPA algorithm details]]
]
#slide(title: [HPA: konfiguracja i granice])[
#codebox[
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: orders-api}
spec:
  scaleTargetRef:
    {apiVersion: apps/v1, kind: Deployment, name: orders-api}
  minReplicas: 3
  maxReplicas: 8
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: {type: Utilization, averageUtilization: 50}
```
]
#sm[Wymaga API metryk. Stabilizacja, tolerancja i brakujące próbki modyfikują prosty rachunek.]
]
#slide(title: [PV, PVC i StorageClass])[
#flow[PVC: żądanie 10 GiB][StorageClass / CSI][PV: przydzielony wolumen]
- PVC: żądanie pojemności i sposobu dostępu przez aplikację.
- PV: obiekt reprezentujący magazyn; może powstać dynamicznie.
- StorageClass: parametry provisioningu, np. sterownik i polityka wiązania.
- Usunięcie PVC: skutek zależy m.in. od reclaimPolicy; możliwe usunięcie danych.
#src[#link("https://kubernetes.io/docs/concepts/storage/persistent-volumes/")[Kubernetes — Persistent Volumes]]
]
#slide(title: [Ruch HTTP do API])[
#flow[Klient][Gateway / Ingress][Service][EndpointSlice][Pod]
- Kontroler bramy realizuje routing host/path i TLS.
- Service daje stabilny punkt dostępu; endpointy wynikają z selektora i gotowości.
- Przypadek standardowy: ruch kierowany do gotowych endpointów.
#src[Istnieją wyjątki konfiguracji, np. publishNotReadyAddresses.]
#src[#link("https://gateway-api.sigs.k8s.io/docs/concepts/api-overview/")[Gateway API — API overview]]
]
#slide(title: [#cloud Wolumen a awaria strefy])[
#data-table(2,
[Zdarzenie],
[Pytanie o storage],
[Nowy Pod],
[Czy może ponownie zamontować wolumen?],
[Utrata węzła],
[Czy wolumen jest niezależny od dysku lokalnego?],
[Utrata strefy],
[Czy dane i możliwość montowania istnieją poza strefą?],
)
- Topologia Podów musi być zgodna z topologią wolumenu.
- Trwałość dysku nie zastępuje kopii chroniącej przed błędnym DELETE.
#src[#link("https://kubernetes.io/docs/concepts/storage/storage-classes/")[Kubernetes — Storage classes]]
]
#slide(title: [#cloud HPA i skalowanie węzłów])[
#flow[HPA: 3 → 5][Brak zasobów na węzłach][Dodatkowe Pody Pending]
- Autoscaler węzłów może dodać pojemność; podlega limitom i opóźnieniom.
- Więcej workerów może przeciążyć bazę lub wyczerpać limit połączeń.
- Maksymalna skala wymaga testu zależności oraz oszacowania kosztu.
#src[#link("https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview")[Microsoft — AKS cluster autoscaler]]
]
#slide(title: [Przypadek: restart co kilka minut])[
#codebox[
```text
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
Restart Count: 12
Limits: memory: 256Mi

# Pomiary tuż przed restartem
RSS: 120 MiB -> 180 MiB -> 254 MiB
CPU: 60m; request CPU: 250m
```
]
#alertblock[Decyzja][Zmienić sondę, zwiększyć pamięć czy dodać repliki? Oddziel działanie doraźne od ustalenia przyczyny.]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://kubernetes.io/docs/concepts/workloads/pods/probes/")[Kubernetes — Probes]
- #link("https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/")[Kubernetes — Resource management]
- #link("https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/")[Kubernetes — HPA]
- #link("https://kubernetes.io/docs/concepts/storage/persistent-volumes/")[Kubernetes — Persistent Volumes]
- #link("https://gateway-api.sigs.k8s.io/docs/concepts/api-overview/")[Gateway API — API overview]
- #link("https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview")[Microsoft — AKS cluster autoscaler]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]
