#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Kubernetes: model działania", subtitle: [API, kontrolery, planowanie i ruch do Podów], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Trzy repliki workera])[
#flow[spec: replicas = 3][API][status: readyReplicas = 2]
- Stan oczekiwany i obserwowany mogą się chwilowo różnić.
- Kontroler próbuje zmniejszać różnicę; brak zasobów może to uniemożliwić.
- Worker sam łączy się z kolejką; odbieranie wiadomości nie wymaga Service.
]
#slide(title: [Control plane i węzeł])[
#data-table(3,
[Control plane],
[Odpowiedzialność],
[Węzeł],
[API server + etcd],
[API i trwały stan obiektów],
[kubelet obserwuje przypisane Pody],
[Kontrolery],
[Działania na podstawie spec/status],
[Runtime uruchamia kontenery],
[Scheduler],
[Wybór węzła dla nowego Poda],
[Sieć i magazyn przez komponenty klastra],
)
#flow[kubectl][API server][etcd]
#src[#link("https://kubernetes.io/docs/concepts/overview/components/")[Kubernetes — Components]]
]
#slide(title: [Rekonsyliacja: zamknięta pętla])[
#flow[Odczyt spec/status][Porównanie][Zmiana przez API]
#align(center)[#sym.arrow.l Powtórny odczyt po zdarzeniu / ponowieniu #sym.arrow.l]
#exblock[ReplicaSet][Oczekiwane: 3 Pody. Istnieją: 2. Kontroler tworzy obiekt Poda; scheduler przypisuje węzeł, kubelet uruchamia kontener.]
- Utworzenie obiektu Poda nie oznacza gotowego procesu.
#src[#link("https://kubernetes.io/docs/concepts/architecture/controller/")[Kubernetes — Controllers]]
]
#slide(title: [Deployment → ReplicaSet → Pody])[
#flow[Deployment: worker][ReplicaSet: v1][Pod A / B / C]
- Deployment zarządza aktualizacją i ReplicaSetami.
- ReplicaSet utrzymuje liczbę Podów pasujących do selektora.
- Pod: wspólna przestrzeń sieciowa kontenerów i zadeklarowane wolumeny.
- Nowa wersja szablonu Poda → nowy ReplicaSet.
#src[#link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Kubernetes — Deployments]]
]
#slide(title: [Manifest Deploymentu])[
#codebox[
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
spec:
  replicas: 3
  selector:
    matchLabels: {app: worker}
  template:
    metadata:
      labels: {app: worker}
    spec:
      containers:
        - name: worker
          image: registry.example.test/worker:v1
```
]
#src[Fragment dydaktyczny: pominięte zasoby, sondy i konfiguracja. Rejestr przykładowy.]
]
#slide(title: [Scheduler: rezerwacja a bieżące zużycie])[
#data-table(4,
[Węzeł],
[Allocatable CPU],
[Suma istniejących requests],
[Nowy Pod: 600m],
[A],
[2000m],
[1600m],
[Brak miejsca],
[B],
[2000m],
[1000m],
[Mieści się przy innych zgodnych warunkach],
)
- Scheduler uwzględnia requests, nie tylko aktualny wykres CPU.
- Dodatkowe ograniczenia: pamięć, affinity, tainty, wolumeny.
- Pending: sprawdź zdarzenia, zanim zwiększysz replicas.
#src[#link("https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/")[Kubernetes — Resource management]]
]
#slide(title: [Service i etykiety: przykład API])[
#codebox[
```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-api
spec:
  selector: {app: orders-api}
  ports:
    - port: 80
      targetPort: 8080
```
]
#flow[orders-api:80][EndpointSlice][Gotowy Pod:8080]
#sm[Service pasuje do etykiet Podów, nie do nazwy Deploymentu.]
#src[#link("https://kubernetes.io/docs/concepts/services-networking/service/")[Kubernetes — Service]]
]
#slide(title: [Dwa różne miejsca awarii])[
#data-table(3,
[Obserwacja],
[Pierwszy odczyt],
[Hipoteza],
[Pending],
[kubectl describe pod],
[Brak CPU / konflikt przypisania],
[CrashLoopBackOff],
[kubectl logs --previous],
[Proces kończy się i jest restartowany],
[Service bez endpointów],
[Etykiety i EndpointSlice],
[Selector lub brak gotowości],
)
#sm[CrashLoopBackOff to opis oczekiwania przed restartem kontenera, nie osobna faza Poda.]
]
#slide(title: [#cloud AKS: granica zarządzania])[
#flow[Microsoft: control plane][API Kubernetes][Zespół: workloady]
- Manifesty, uprawnienia, obrazy i aktualizacje aplikacji po stronie zespołu.
- Pojemność i aktualizacje node pooli zależne od wybranego trybu i konfiguracji.
- Zarządzany control plane nie naprawia błędnego selektora Service.
#src[#link("https://learn.microsoft.com/azure/aks/core-aks-concepts")[Microsoft — AKS core concepts]]
]
#slide(title: [#cloud Pody a pojemność węzłów])[
#flow[Więcej replik][Pod Pending][Autoscaler węzłów][Nowy węzeł]
- HPA zmienia liczbę replik; autoscaler klastra zmienia pojemność.
- Nowy węzeł wymaga czasu, limitu zasobów i dostępnej pojemności dostawcy.
- Błąd etykiet lub startu procesu nie znika po dodaniu węzła.
#src[#link("https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview")[Microsoft — AKS cluster autoscaler]]
]
#slide(title: [Przypadek: Pody działają, Service nie])[
#codebox[
```text
$ kubectl get pods --show-labels
NAME           READY   STATUS    LABELS
orders-7d-a     1/1     Running   app=orders-api
orders-7d-b     1/1     Running   app=orders-api

$ kubectl get service orders-api -o yaml
spec:
  selector: {app: orders}

$ kubectl get endpointslice -l kubernetes.io/service-name=orders-api
# brak endpointów
```
]
#alertblock[Diagnoza][Wskaż minimalną zmianę i odczyt potwierdzający jej skuteczność. Czy restart Podów pomoże?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://kubernetes.io/docs/concepts/overview/components/")[Kubernetes — Components]
- #link("https://kubernetes.io/docs/concepts/architecture/controller/")[Kubernetes — Controllers]
- #link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Kubernetes — Deployments]
- #link("https://kubernetes.io/docs/concepts/services-networking/service/")[Kubernetes — Service]
- #link("https://learn.microsoft.com/azure/aks/core-aks-concepts")[Microsoft — AKS concepts]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]
