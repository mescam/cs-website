#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud

#show: typslides.with(
  ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt,
  show-progress: true, show-page-numbers: true,
)
#set text(lang: "pl")

#front-slide(
  title: "Kubernetes: model działania",
  subtitle: [Od trzech instancji do działającej usługi],
  authors: "mgr inż. Jakub Woźniak",
  info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27],
)

#slide(title: [Obraz jest gotowy. Kto utrzyma trzy instancje?])[
  #alertblock[Przypadek][
    Mamy obraz workera systemu zamówień. Chcemy utrzymywać trzy instancje
    na kilku serwerach, także po zakończeniu procesu lub awarii serwera.
  ]
  - Kto wybierze miejsce uruchomienia każdej instancji?
  - Kto zauważy brak instancji i uruchomi zastępstwo?
  - Jak klient znajdzie API, gdy jego instancje zostaną wymienione?

  #src[Kontynuacja wykładu 2: obraz umożliwia tworzenie wymienialnych instancji.]
]

#slide(title: [Plan: od instancji do usługi])[
  - Klaster, węzeł i Pod: gdzie działa aplikacja.
  - Stan oczekiwany, kontrolery i Deployment: kto utrzymuje instancje.
  - Scheduler: gdzie zmieści się kolejny Pod.
  - Service i etykiety: jak skierować ruch do aplikacji.
  - #cloud AKS: odpowiedzialność i pojemność klastra.
  - Diagnoza: Pody działają, ale Service nie obsługuje ruchu.
]

#slide(title: [Klaster, węzeł i Pod])[
  #data-table(2,
    [Pojęcie], [Rola],
    [Klaster], [Control plane oraz węzły wykonujące aplikacje],
    [Węzeł], [Maszyna fizyczna lub wirtualna uruchamiająca Pody],
    [Pod], [Jednostka uruchomienia jednego lub kilku kontenerów na jednym węźle],
  )
  - Kontenery Poda współdzielą przestrzeń sieciową i mogą montować wspólne wolumeny.
  - W przykładzie: jeden Pod zawiera jeden kontener workera; trzy repliki to trzy Pody.
  - Zastąpienie Poda oznacza nowy obiekt; jego adres IP może się zmienić.

  #src[#link("https://kubernetes.io/docs/concepts/workloads/pods/")[Kubernetes — Pods]]
]

#slide(title: [Opisujemy stan, który chcemy utrzymywać])[
  #cols[
    #defblock[spec: stan oczekiwany][Chcemy utrzymywać trzy repliki workera.]
  ][
    #exblock[status: stan obserwowany][Istnieją trzy Pody, ale tylko dwa są gotowe.]
  ]
  - API Kubernetes udostępnia obiekty opisujące konfigurację i obserwowany stan.
  - Kontrolery cyklicznie dążą do stanu oczekiwanego; reakcje wymagają czasu.
  - Brak zasobów lub błąd aplikacji może uniemożliwić osiągnięcie celu.

  #sm[Gotowość oznacza zdolność do obsługi pracy według warunków Poda. Sondy omówimy na wykładzie 4.]
]

#slide(title: [Deployment → ReplicaSet → Pody])[
  #flow[Deployment: worker][ReplicaSet][Pod A / B / C]
  - Deployment opisuje szablon Poda i zarządza aktualizacją aplikacji.
  - ReplicaSet utrzymuje zadaną liczbę Podów na podstawie szablonu i selektora etykiet.
  - Zmiana szablonu, np. obrazu, powoduje wdrożenie przez odpowiedni ReplicaSet.

  #alertblock[Liczba a gotowość][
    Trzy istniejące Pody, z których jeden jest niegotowy, nie oznaczają,
    że ReplicaSet automatycznie utworzy czwarty Pod.
  ]
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
  #src[selector wskazuje etykiety Podów. Przykład pomija zasoby, sondy i konfigurację; rejestr jest przykładowy.]
]

#slide(title: [Control plane zarządza, węzeł wykonuje])[
  #cols[
    #defblock[Control plane][
      - API server: dostęp do obiektów.
      - etcd: trwały zapis stanu obiektów.
      - Kontrolery: reakcje na różnice stanu.
      - Scheduler: wybór węzła dla Poda.
    ]
  ][
    #exblock[Na węźle][
      - Kubelet obsługuje przypisane Pody.
      - Runtime uruchamia kontenery na zlecenie kubeleta.
      - Komponenty sieci i magazynu zapewniają łączność i wolumeny.
    ]
  ]
  #flow[kubectl][API server][etcd]
  #src[#link("https://kubernetes.io/docs/concepts/overview/components/")[Kubernetes — Components]]
]

#slide(title: [Rekonsyliacja: od brakującego Poda do procesu])[
  #flow[Odczyt stanu][Porównanie z celem][Działanie]
  #exblock[ReplicaSet: oczekiwane 3 Pody, istnieją 2][
    + Kontroler tworzy obiekt brakującego Poda przez API.
    + Scheduler wybiera węzeł i zapisuje przypisanie przez API.
    + Kubelet zleca runtime'owi uruchomienie kontenera.
    + Stan jest ponownie obserwowany; pętla trwa dalej.
  ]
  - Zapis obiektu, uruchomienie procesu i osiągnięcie gotowości to osobne etapy.
  #src[#link("https://kubernetes.io/docs/concepts/architecture/controller/")[Kubernetes — Controllers]]
]

#slide(title: [Scheduler: gdzie zmieści się nowy Pod?])[
  #sm[Request CPU to deklarowane zapotrzebowanie. 1000m = 1 CPU. Allocatable to pojemność udostępniona Podom.]
  #data-table(4,
    [Węzeł], [Allocatable CPU], [Suma requests], [Nowy Pod: 600m],
    [A], [2000m], [1600m], [Nie: 1600 + 600 > 2000],
    [B], [2000m], [1000m], [Tak: 1000 + 600 ≤ 2000],
  )
  - Przy sprawdzaniu pojemności CPU scheduler porównuje requests z allocatable.
  - Niskie bieżące zużycie CPU nie zwalnia zadeklarowanych requests.
  - Wyliczenie zakłada zgodność pamięci i pozostałych warunków przypisania.
  #src[#link("https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/")[Kubernetes — Resource management]]
]

#slide(title: [Service daje klientom stabilny punkt dostępu])[
  - Przechodzimy od workera do API zamówień: API przyjmuje żądania klientów.
  - Pody API są wymieniane, a ich adresy IP mogą się zmieniać.
  - Service udostępnia stabilną nazwę DNS i, w domyślnym typie ClusterIP, wirtualny adres IP w klastrze.
  - Selektor etykiet wskazuje Pody obsługujące ten Service.

  #exblock[Dlaczego worker nie potrzebował Service?][
    Worker sam inicjuje połączenie z kolejką. Konsumpcja wiadomości nie wymaga
    wystawienia punktu dostępu do workera.
  ]
  #src[#link("https://kubernetes.io/docs/concepts/services-networking/service/")[Kubernetes — Service]]
]

#slide(title: [Service wybiera Pody po etykietach])[
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
  - Pasuje do Podów z etykietą app=orders-api w tym samym namespace.
  - Klient używa portu 80 Service; aplikacja nasłuchuje na porcie 8080 Poda.
  #src[Domyślny typ: ClusterIP. Nazwa Deploymentu nie decyduje o dopasowaniu.]
]

#slide(title: [Ruch do Poda i informacja o endpointach])[
  #defblock[Droga żądania — typowy Service ClusterIP][
    Klient → adres Service:80 → wybrany gotowy Pod:8080
  ]
  #exblock[Skąd wiadomo, które Pody wybrać?][
    Kontroler zapisuje adresy i warunki gotowości w obiektach EndpointSlice.
    kube-proxy lub zastępujący go komponent sieciowy odczytuje te dane
    i konfiguruje obsługę ruchu Service.
  ]
  #sm[EndpointSlice opisuje endpointy; sam nie przekazuje pakietów. Omawiamy domyślne kierowanie ruchu do gotowych Podów.]
  #src[#link("https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/")[Kubernetes — EndpointSlices]]
]

#slide(title: [Gdzie szukać przyczyny awarii?])[
  #data-table(3,
    [Obserwacja], [Pierwszy odczyt], [Hipoteza],
    [Pending], [#text(size: 14pt)[`kubectl describe pod <nazwa>`]], [Np. brak CPU; zdarzenia wskażą etap problemu],
    [CrashLoopBackOff], [#text(size: 14pt)[`kubectl logs <nazwa> --previous`]], [Kontener kończy pracę i jest restartowany],
    [Service bez gotowych endpointów], [Etykiety i EndpointSlice], [Błędny selektor lub brak gotowości],
  )
  #sm[Pending obejmuje oczekiwanie na przypisanie oraz przygotowanie kontenerów. CrashLoopBackOff opisuje oczekiwanie przed kolejnym restartem kontenera.]
]

#slide(title: [#cloud AKS: granica zarządzania])[
  #flow[Microsoft: control plane][API Kubernetes][Zespół: aplikacje]
  - Zespół odpowiada za manifesty, uprawnienia, obrazy i aktualizacje aplikacji.
  - Odpowiedzialność za pojemność i aktualizacje węzłów zależy od trybu usługi i konfiguracji.
  - Zarządzany control plane nie naprawia błędnego selektora Service.
  #src[#link("https://learn.microsoft.com/azure/aks/core-aks-concepts")[Microsoft — AKS core concepts]]
]

#slide(title: [#cloud Repliki aplikacji a pojemność klastra])[
  #flow[Więcej replik][Brak miejsca][Pody Pending]
  - HPA (Horizontal Pod Autoscaler) zmienia liczbę replik na podstawie metryk.
  - Autoscaler węzłów może dodać węzeł, jeśli umożliwi to przypisanie oczekujących Podów.
  - Wymaga włączenia i odpowiedniej konfiguracji; podlega limitom i dostępności zasobów dostawcy.
  - Dodanie węzła wymaga czasu i nie usuwa błędu selektora ani aplikacji.
  #src[#link("https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview")[Microsoft — AKS cluster autoscaler]. Obliczenia HPA na wykładzie 4.]
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
NAME               ADDRESSTYPE   PORTS   ENDPOINTS
orders-api-abcde    IPv4          8080    <none>
```
  ]
  #alertblock[Diagnoza][Wskaż minimalną zmianę i sposób potwierdzenia jej skuteczności. Czy restart Podów pomoże?]
  #src[Skrócone dane dydaktyczne; wszystkie obiekty są w tym samym namespace.]
]

#slide(title: [Kluczowe wnioski])[
  - Kubernetes utrzymuje opisany stan przez wiele współpracujących pętli kontroli.
  - Deployment zarządza replikami i aktualizacją; scheduler wybiera węzeł, a kubelet organizuje uruchomienie kontenerów.
  - Liczba Podów, uruchomienie procesów i gotowość do ruchu to osobne obserwacje.
  - Service zapewnia stabilny dostęp; etykiety i gotowość decydują o jego endpointach.
  - #cloud Zarządzany klaster nadal wymaga poprawnej konfiguracji aplikacji oraz dostępnej pojemności.
]

#slide(title: [Źródła i lektury])[
  #text(size: 16pt)[
    - #link("https://kubernetes.io/docs/concepts/workloads/pods/")[Kubernetes — Pods]
    - #link("https://kubernetes.io/docs/concepts/overview/components/")[Kubernetes — Components]
    - #link("https://kubernetes.io/docs/concepts/architecture/controller/")[Kubernetes — Controllers]
    - #link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Kubernetes — Deployments]
    - #link("https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/")[Kubernetes — Resource management]
    - #link("https://kubernetes.io/docs/concepts/services-networking/service/")[Kubernetes — Service]
    - #link("https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/")[Kubernetes — EndpointSlices]
    - #link("https://learn.microsoft.com/azure/aks/core-aks-concepts")[Microsoft — AKS concepts]
    - #link("https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview")[Microsoft — AKS cluster autoscaler]
  ]
  #src[Dane przypadków są przykładami dydaktycznymi.]
]
