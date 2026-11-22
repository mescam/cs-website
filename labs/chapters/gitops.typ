#pagebreak()

= Część IV. GitOps — stan oczekiwany w repozytorium Git

Ręczne `kubectl apply` wprowadza do klastra zmianę, której nikt nie zapisał w repozytorium. Klaster i repozytorium zaczynają się różnić, a odtworzenie środowiska wymaga odtworzenia czyjejś pamięci. GitOps odwraca zależność: repozytorium Git jest źródłem prawdy, a kontroler w klastrze porównuje stan rzeczywisty z nim i usuwa różnicę.

W tej części Argo CD pełni rolę kontrolera, a repozytorium manifestów powstaje na GitLabie uczelni (`git.cs.put.poznan.pl`); sekcja B2 opisuje wariant awaryjny z Giteą uruchamianą w klastrze. Ćwiczenie obejmuje instalację, pierwsze wdrożenie, rozbieżność, samonaprawę, usuwanie zasobów i wycofanie zmiany. Każde zadanie kończy się pomiarem, który potwierdza, że klaster naprawdę zmienił stan.

== Punkt startowy

Potrzebne są Docker, Minikube, `kubectl`, `git`, `curl`, przeglądarka oraz konto na `git.cs.put.poznan.pl`. Klaster można uruchomić od zera:

```bash
docker info
minikube start -p zsr --driver=docker --cpus=2 --memory=4096
kubectl config use-context zsr
kubectl get nodes
```

Profil `zsr` i namespace `zsr` mogą pochodzić z wcześniejszych zajęć; ta część tworzy własne namespace `argocd` i `zsr-gitops`; wariant awaryjny tworzy dodatkowo namespace `gitea`. Pliki potrzebne do ćwiczenia znajdują się w katalogu `materialy/gitops` paczki `docker-materialy.zip`. Należy pobrać #link("https://www.cs.put.poznan.pl/jwozniak/labs/docker-materialy.zip")[docker-materialy.zip] i rozpakować go, jeżeli nie został jeszcze rozpakowany. W poleceniach `<ścieżka>` oznacza katalog, w którym rozpakowano materiały.

Przed rozpoczęciem należy sprawdzić, czy w klastrze działają już wydania z części III. Ta część nie wymaga Traefika ani stosu monitoringu, a przy 4 GB pamięci oba zestawy mogą się nie zmieścić. W razie potrzeby należy zatrzymać zbędne wydania albo uruchomić klaster z większym limitem pamięci.

== Plan pracy na kilka spotkań

#table(
  columns: (auto, 1fr, 1fr), inset: 6pt, stroke: 0.4pt,
  table.header([*Spotkanie*], [*Zakres*], [*Efekt pracy*]),
  [1], [Argo CD, repozytorium Git, pierwsza aplikacja (A–C)], [Application zsynchronizowana, strona odpowiada],
  [2], [Rozbieżność, prune, wycofanie (D–F)], [Samonaprawa, usuwanie i powrót do wersji 1 potwierdzone],
  [3], [Druga aplikacja i rozszerzenia (G) — opcjonalnie], [Własna Application i samodzielne ćwiczenie],
)

Zadania A–F są obowiązkowe i mieszczą się w dwóch spotkaniach po 135 minut. Trzecie spotkanie jest opcjonalne: G dla szybszych grup oraz rozszerzenia wskazane przez prowadzącego.

== Od ręcznego wdrożenia do GitOps

#table(
  columns: (1fr, 1fr), inset: 6pt, stroke: 0.4pt,
  [*Ręczne wdrożenie*], [*GitOps*],
  [`kubectl apply` w terminalu], [commit i push do repozytorium],
  [stan klastra jest prawdą], [stan w repozytorium jest prawdą],
  [historia w powłoce], [historia w commitach],
  [odtworzenie z pamięci], [odtworzenie z repozytorium],
  [brak automatycznego wykrywania dryfu], [kontroler porównuje i naprawia],
)

= A. Instalacja Argo CD

Argo CD działa w klastrze jako zestaw kontrolerów. Serwer API obsługuje interfejs i CLI, serwer repozytoriów pobiera manifesty z Gita, a kontroler aplikacji porównuje je ze stanem klastra. Aplikacja w Argo CD to obiekt `Application`: wskazuje repozytorium, ścieżkę, gałąź i docelowy namespace.

Należy utworzyć namespace i zastosować manifest instalacyjny w wersji `v3.6.2`:

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.6.2/manifests/install.yaml
```

Flaga `--server-side` jest wymagana: manifest zawiera definicję CRD, której adnotacja przekracza limit przyjęty przez klasyczne `kubectl apply`. Bez tej flagi instalacja kończy się komunikatem o zbyt dużej adnotacji, mimo że część obiektów zdąży powstać.

Następnie należy poczekać na gotowość Podów i odczytać hasło administratora:

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Interfejs jest dostępny po przekierowaniu portu w osobnym terminalu:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Należy otworzyć `https://localhost:8080`, zaakceptować certyfikat ćwiczeniowy i zalogować się jako `admin` z odczytanym hasłem. Hasło jest przykładowe; nie należy używać go poza klastrem ćwiczeniowym.

*Weryfikacja:* w namespace `argocd` działa siedem Podów w stanie `Running`, interfejs otwiera się pod `https://localhost:8080`, a logowanie `admin` przyjmuje hasło z `argocd-initial-admin-secret`. Bez flagi `--server-side` instalacja nie przechodzi.

= B. Repozytorium Git na GitLabie

GitOps potrzebuje repozytorium, do którego Argo CD ma dostęp z klastra. W tym ćwiczeniu repozytorium powstaje na GitLabie uczelni: `git.cs.put.poznan.pl`. Repozytorium musi być publiczne — Argo CD klonuje je bez danych dostępowych; repozytorium prywatne wymagałoby dodania poświadczeń do Argo CD i wykracza poza zakres ćwiczenia. Jeżeli klaster nie osiąga GitLaba, sekcja B2 opisuje wariant awaryjny z Giteą w klastrze. Należy wybrać jeden wariant i używać go w zadaniach C–G.

== B1. Repozytorium na GitLabie (wariant podstawowy)

Należy zalogować się na `https://git.cs.put.poznan.pl` i utworzyć projekt: *New project* → *Create blank project*, nazwa `zsr-gitops`, widoczność *Public*, bez inicjalizacji plikiem README. Puste repozytorium przyjmie pierwszy push; repozytorium z commitem odrzuci go jako niezwiązane historie.

Na stanowisku należy przygotować katalog roboczy i wypchnąć manifesty:

```bash
mkdir -p ~/zsr-gitops && cd ~/zsr-gitops
cp -R <ścieżka>/materialy/gitops/repo/. .
git init -b main
git add .
git commit -m "Początkowe manifesty aplikacji"
git remote add origin https://git.cs.put.poznan.pl/<użytkownik>/zsr-gitops.git
git push -u origin main
```

`<użytkownik>` to nazwa konta GitLaba. Przy `git push` Git poprosi o poświadczenia; należy podać nazwę konta i hasło GitLaba. Jeżeli serwer odmówi hasła, należy utworzyć personal access token (*Settings* → *Access tokens*, zakres `write_repository`) i użyć go w miejsce hasła. Poświadczeń nie należy zapisywać w repozytorium.

*Weryfikacja:* `git ls-remote origin` zwraca gałąź `main`, w interfejsie GitLaba widać commit i pliki `apps/demo`, a strona projektu jest publiczna i widoczna bez logowania. Push do repozytorium utworzonego z README kończy się błędem o niezwiązanych historiach.

== B2. Wariant awaryjny: Gitea w klastrze

Ten wariant pomija GitLaba: serwer Git uruchamia się w klastrze, więc ćwiczenie działa nawet wtedy, gdy klaster nie osiąga sieci zewnętrznej. Gitea jest lekkim serwerem Git; dzięki temu repozytorium jest dostępne bez zewnętrznego konta, a Argo CD może je pobierać po adresie usługi. Manifest `materialy/gitops/gitea.yaml` tworzy namespace, wolumen trwały, Deployment i Service na porcie 3000.

Należy zastosować manifest i poczekać na gotowość:

```bash
kubectl apply -f <ścieżka>/materialy/gitops/gitea.yaml
kubectl -n gitea wait --for=condition=Ready pods \
  --selector=app=gitea --timeout=180s
```

Konto administratora tworzy się jednorazowo poleceniem w kontenerze:

```bash
kubectl -n gitea exec deploy/gitea -- \
  su git -c "gitea admin user create --username lab --password lab1234 \
  --email lab@example.com --admin"
```

Kontener startuje jako root, a CLI Gitei odmawia pracy jako root; dlatego polecenie przełącza się na użytkownika `git`. Następnie należy przekierować port Gitei w osobnym terminalu:

```bash
kubectl -n gitea port-forward svc/gitea 3000:3000
```

W przeglądarce `http://localhost:3000` należy zalogować się jako `lab` z hasłem `lab1234`, utworzyć publiczne repozytorium `zsr-gitops` i *nie* inicjalizować go plikiem README. Na stanowisku należy przygotować katalog roboczy i wypchnąć manifesty:

```bash
mkdir -p ~/zsr-gitops && cd ~/zsr-gitops
cp -R <ścieżka>/materialy/gitops/repo/. .
git init -b main
git add .
git commit -m "Początkowe manifesty aplikacji"
git remote add origin http://localhost:3000/lab/zsr-gitops.git
git push -u origin main
```

Przy `git push` Git może poprosić o nazwę użytkownika i hasło; należy użyć `lab` i `lab1234`. Adres `http://localhost:3000/...` jest adresem z perspektywy stanowiska. Argo CD działa w klastrze i będzie używać adresu `http://gitea.gitea.svc.cluster.local:3000/...`; to ten sam obiekt, widziany z dwóch miejsc.

*Weryfikacja:* `git ls-remote origin` zwraca gałąź `main`, w Gitei widać commit i pliki `apps/demo`, a strona repozytorium jest publiczna. Push do repozytorium utworzonego z README kończy się błędem o niezwiązanych historiach.

= C. Pierwsza aplikacja w Argo CD

Plik `materialy/gitops/repo/argocd/application.yaml` definiuje obiekt `Application`. Pole `source` wskazuje repozytorium, gałąź i katalog `apps/demo`; pole `destination` wskazuje klaster i namespace `zsr-gitops`; `syncPolicy.syncOptions` zawiera `CreateNamespace=true`. Obiekt Application jest jedynym elementem aplikowanym ręcznie — reszta manifestów przychodzi z repozytorium.

W pliku `argocd/application.yaml` w katalogu roboczym należy zamienić `<użytkownik>` na nazwę konta GitLaba, zapisać zmianę, wykonać commit i push. W wariancie awaryjnym (B2) zamiast tego adresu wpisuje się `http://gitea.gitea.svc.cluster.local:3000/lab/zsr-gitops.git`. Następnie należy zastosować obiekt i sprawdzić stan:

```bash
kubectl apply -f argocd/application.yaml
kubectl -n argocd get application zsr-demo
```

Na początku aplikacja jest w stanie `OutOfSync`, ponieważ w klastrze nie ma jeszcze jej zasobów. W interfejsie Argo CD należy otworzyć `zsr-demo`, wybrać `Sync`, pozostawić `Prune` wyłączone i potwierdzić `Synchronize`. Następnie w osobnym terminalu należy przekierować port usługi:

```bash
kubectl -n zsr-gitops port-forward svc/zsr-demo 8081:80
```

W głównym terminalu należy sprawdzić zasoby i odpowiedź usługi:

```bash
kubectl -n zsr-gitops get deploy,svc,pods
curl --fail http://localhost:8081
```

Strona powinna zawierać tekst `GitOps: wersja 1`. Dwa Pody obsługują Service, a Deployment ma dwie gotowe repliki.

*Weryfikacja:* `kubectl -n argocd get application zsr-demo` pokazuje `Synced` i `Healthy`, w namespace `zsr-gitops` działają dwa Pody, a `curl` zwraca `wersja 1`. Stan `Synced` oznacza zgodność manifestów; `Healthy` oznacza, że zasoby działają. Te dwa warunki trzeba sprawdzać osobno.

= D. Rozbieżność i samonaprawa

Dryf powstaje wtedy, gdy ktoś zmieni klaster poza repozytorium. Należy zmienić liczbę replik bezpośrednio w klastrze:

```bash
kubectl -n zsr-gitops scale deployment zsr-demo --replicas=4
kubectl -n zsr-gitops get pods
```

W interfejsie Argo CD aplikacja przejdzie w `OutOfSync`, ale przy polityce manualnej nie naprawi stanu. Należy odświeżyć widok i porównać manifest. Następnie w pliku `argocd/application.yaml` należy zmienić politykę na automatyczną, wykonać commit i push:

```yaml
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Po `git commit`, `git push` i ponownym `kubectl apply -f argocd/application.yaml` Argo CD zacznie cyklicznie porównywać stan. Należy powtórzyć skalowanie do czterech replik i odczekać na kolejne porównanie; liczba replik wróci do dwóch.

*Weryfikacja:* po ręcznej zmianie na cztery repliki aplikacja jest `OutOfSync`, a po włączeniu `selfHeal: true` wraca do dwóch replik bez ręcznego poprawiania Deploymentu. Zmiana w klastrze została cofnięta, ponieważ nie było jej w repozytorium.

= E. Usuwanie zasobów (prune)

Polityka `prune` decyduje, czy zasób usunięty z repozytorium ma zniknąć z klastra. Należy dodać do repozytorium plik `apps/demo/extra.yaml` z dodatkowym ConfigMap o nazwie `zsr-demo-extra`, wypchnąć go i zsynchronizować aplikację. Następnie należy usunąć plik z repozytorium, wypchnąć commit i odświeżyć aplikację. Przy `prune: false` zasób pozostaje w klastrze, choć aplikacja jest `OutOfSync`.

Po zmianie polityki na `prune: true` w pliku `argocd/application.yaml`, wykonaniu `git commit` i `git push` oraz ponownym `kubectl apply -f argocd/application.yaml` zasób znika po kolejnej synchronizacji. Należy potwierdzić:

```bash
kubectl -n zsr-gitops get configmap zsr-demo-extra
```

*Weryfikacja:* przy `prune: false` ConfigMap nadal istnieje po usunięciu manifestu z repozytorium; przy `prune: true` polecenie zwraca `NotFound`. Należy wskazać, dlaczego `prune: true` jest wygodne i niebezpieczne jednocześnie.

= F. Wycofanie zmiany przez Git

W pliku `apps/demo/configmap.yaml` należy zmienić tekst `wersja 1` na `wersja 2`, wykonać commit, push i synchronizację. Strona powinna zwracać nową wersję. Wycofanie nie polega na `kubectl rollout undo`, lecz na nowym commicie odwracającym zmianę:

```bash
git revert --no-edit HEAD
git push
```

Po synchronizacji strona wraca do `wersja 1`, a historia repozytorium zawiera zarówno zmianę, jak i jej odwrócenie. Ręczne wykonanie `kubectl rollout undo` zostałoby cofnięte przez `selfHeal`, ponieważ repozytorium nadal wskazywałoby wersję 2.

*Weryfikacja:* po `git revert` strona zwraca `wersja 1`, a `git log --oneline` pokazuje commit odwracający. Wycofanie jest widoczne w historii repozytorium, a nie tylko w stanie klastra.

= G. Druga aplikacja (zadanie samodzielne)

Należy dodać do repozytorium katalog `apps/whoami` z Deploymentem i Service dla obrazu `traefik/whoami:v1.12.0`. Aplikacja ma dwa Pody, Service `whoami` na porcie 80 i własny obiekt `Application` w pliku `argocd/whoami.yaml`, z automatyczną synchronizacją, `selfHeal: true` i `prune: true`.

Wymagania:

1. Obraz jest przypięty do wersji, a namespace pozostaje `zsr-gitops`.
2. Obiekt `Application` wskazuje katalog `apps/whoami` i adres repozytorium z zadania B, a nie `localhost`.
3. Po synchronizacji `curl` zwraca nazwę Poda, a usunięcie jednego Poda powoduje odtworzenie repliki.
4. Ręczne skalowanie jest cofane przez `selfHeal`.

Po wypchnięciu manifestów należy zastosować obiekt poleceniem `kubectl apply -f argocd/whoami.yaml`. Aby sprawdzić odpowiedź, należy w osobnym terminalu przekierować port usługi `whoami`:

```bash
kubectl -n zsr-gitops port-forward svc/whoami 8082:80
```

W głównym terminalu należy wykonać:

```bash
curl --fail http://localhost:8082
```

*Weryfikacja:* `kubectl -n argocd get application whoami` pokazuje `Synced` i `Healthy`, w `zsr-gitops` działają dwa Pody aplikacji `whoami`, a `curl` zwraca odpowiedź z nazwą Poda. Zmiana liczby replik w klastrze wraca do dwóch.

= Diagnostyka GitOps

- `metadata.annotations: Too long`: instalacja Argo CD wymaga `--server-side`; klasyczne `apply` nie mieści adnotacji CRD.
- Push odrzucony z kodem 401: poświadczenia GitLaba są nieaktualne; należy użyć nazwy konta i hasła albo personal access tokenu z zakresem `write_repository`.
- Push odrzucony jako niezwiązane historie: repozytorium zostało utworzone z README; należy utworzyć puste repozytorium albo użyć `git pull --rebase`.
- Aplikacja w stanie `Unknown` lub `ComparisonError`: należy sprawdzić adres repozytorium w obiekcie `Application` i log `kubectl -n argocd logs deploy/argocd-repo-server`; adres musi być osiągalny z klastra, a `<użytkownik>` — zastąpiony nazwą konta.
- Repozytorium jest prywatne: Argo CD nie ma poświadczeń; należy je upublicznić albo dodać dane dostępowe do Argo CD.
- Klaster nie osiąga `git.cs.put.poznan.pl`: Argo CD zgłasza błąd porównania; wariant awaryjny (B2) pozwala dokończyć ćwiczenie bez sieci zewnętrznej.
- Gitea nie startuje, PVC w stanie `Pending` (wariant B2): należy sprawdzić `kubectl -n gitea describe pvc gitea-data` i pojemność klastra.
- `gitea admin user create` kończy się błędem uruchomienia jako root (wariant B2): należy wykonać polecenie jako użytkownik kontenera, np. przez `su`.
- Interfejs Argo CD nie otwiera się: przekierowanie portu działa w osobnym terminalu; po jego zamknięciu trzeba uruchomić je ponownie.
- Aplikacja `Synced`, ale strona nie działa: należy sprawdzić `Healthy`, gotowość Podów i logi; zgodność manifestów nie dowodzi działania aplikacji.
- `selfHeal` nie cofa zmiany: polityka musi być `automated`, a porównanie cykliczne; ręczne odświeżenie w interfejsie przyspiesza reakcję.
- `prune` nie usuwa zasobu: polityka jest wyłączona albo manifest nadal istnieje w innej ścieżce repozytorium.
- Zmiana `Application` nie działa: obiekt jest aplikowany ręcznie; sam commit do repozytorium nie zmienia obiektu Application.

= Odbiór i zakończenie

Do odbioru należy przedstawić repozytorium z manifestami, działającą aplikację `zsr-demo`, potwierdzoną samonaprawę, wynik `prune` i wycofanie przez `git revert`. Należy wyjaśnić różnicę między `Synced` i `Healthy`, wskazać, gdzie w repozytorium jest obiekt `Application`, oraz dlaczego adres repozytorium w aplikacji musi być osiągalny z klastra: w wariancie podstawowym jest to publiczny adres GitLaba, w wariancie awaryjnym adres usługi Gitei.

Po demonstracji należy zamknąć przekierowania portów i zatrzymać klaster poleceniem `minikube stop -p zsr`. Usunięcie klastra (`minikube delete -p zsr`) kasuje również repozytorium Gitei i stan Argo CD; dane ćwiczenia nie są kopią zapasową.

= Pytania końcowe i źródła

1. Dlaczego `selfHeal` cofa ręczną zmianę, a `prune` może usunąć zasób, którego nikt nie zamierzał usuwać?
2. Co oznaczają osobno stany `Synced` i `Healthy`? Kiedy aplikacja może być `Synced`, ale nie `Healthy`?
3. Dlaczego wycofanie zmiany przez `git revert` jest trwalsze niż `kubectl rollout undo`?
4. Dlaczego obiekt `Application` wskazuje adres repozytorium osiągalny z klastra, a nie `localhost`?
5. Jakie dane wrażliwe mogą trafić do repozytorium i jak temu zapobiec?
6. Czym różni się aplikacja manualna od automatycznej w momencie, gdy repozytorium jest niedostępne?

#link("https://argo-cd.readthedocs.io/")[Argo CD] · #link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/")[Automatyczna synchronizacja] · #link("https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/")[Specyfikacja Application] · #link("https://docs.gitea.com/")[Gitea] · #link("https://opengitops.dev/")[OpenGitOps]
