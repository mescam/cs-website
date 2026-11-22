# Plan redakcyjny — GitOps i Argo CD (część IV)

Dokument decyzyjny dla nowej części skryptu `1-docker.typ`. Nie jest materiałem
studenckim. Zastępuje samodzielny skrypt `5-gitops.tex` w zakresie ćwiczenia.

## Miejsce w kursie

Część IV domyka skrypt: po Dockerze, Kubernetesie i monitoringu pokazuje, skąd
klaster ma brać stan pożądany. Student zaczyna od zera: własny klaster Minikube,
własne repozytorium Gitea i własna instancja Argo CD. Nie zakładamy stanu z części
I–III.

## Analiza starego skryptu (`5-gitops.tex`)

| Problem | Konsekwencja | Decyzja w nowej części |
|---|---|---|
| `nginx:latest`, manifest `stable` | niepowtarzalny wynik | `nginx:1.30.7`, Argo CD `v3.6.2`, Gitea `28.4.0` |
| brak `--server-side` przy instalacji | CRD przekracza limit adnotacji | jawna flaga i wpis w diagnostyce |
| GitLab na zewnątrz | zależność od konta i sieci | **GitLab uczelni jako wariant podstawowy** (konto, publiczne repo, HTTPS); Gitea w klastrze jako wariant awaryjny, gdy klaster nie osiąga GitLaba |
| adres `localhost` w Application | Argo CD nie widzi localhost studenta | URL z zadania B: `https://git.cs.put.poznan.pl/<użytkownik>/zsr-gitops.git` albo usługa Gitei |
| brak `Application` w YAML | brak wersjonowania i odtwarzalności | obiekt `Application` w repozytorium |
| brak rozróżnienia manual/automated | student nie wie, kiedy działa self-heal | osobne zadania C i D |
| brak prune i rollback | GitOps sprowadzony do `kubectl apply` | zadania E i F |
| ręczne `kubectl apply` manifestów | omija uzgadnianie | tylko `Application` aplikowana ręcznie |
| brak weryfikacji i diagnostyki | brak kryteriów odbioru | `*Weryfikacja:*` w każdym zadaniu i katalog pułapek |

## Szkielet zadań

| Zadanie | Treść | Kryterium |
|---|---|---|
| A | Instalacja Argo CD i dostęp do UI | Pody gotowe, UI i hasło działają |
| B1 | GitLab uczelni: projekt, push, `git ls-remote` widzi `main` | publiczne repo z manifestami |
| B2 | awaryjnie: Gitea w klastrze (gdy klaster nie osiąga GitLaba) | jak wyżej, bez sieci zewnętrznej |
| C | `Application` manualna, pierwsza synchronizacja | strona `wersja 1`, Pody gotowe |
| D | dryf i self-heal | skalowanie w klaster wraca do 2 replik |
| E | prune | dodatkowy ConfigMap znika dopiero po `prune: true` |
| F | wycofanie zmian przez Git | `git revert` przywraca `wersja 1` |
| G | druga aplikacja `whoami` | własna `Application`, automated sync |

## Wersje i materiały

- Argo CD `v3.6.2` — manifest `manifests/install.yaml`.
- Repozytorium: `git.cs.put.poznan.pl/<użytkownik>/zsr-gitops.git` (wariant podstawowy); awaryjnie Gitea `gitea/gitea:28.4.0` — SQLite, PVC 1 GiB, port 3000.
- nginx `1.30.7`, whoami `traefik/whoami:v1.12.0`.
- Materiały: `labs/draft/materialy/gitops/` (Gitea, repo demo, Application z placeholderem `<użytkownik>`).

## Weryfikacja ścieżek (22.11.2026)

- **GitLab HTTPS (B1):** potwierdzona end-to-end na realnym `git.cs.put.poznan.pl` — push, klonowanie przez Argo CD, auto-sync, self-heal, `git revert`. W laboratorium klaster osiąga GitLab bezpośrednio, więc bez dodatkowej konfiguracji.
- **Gitea (B2):** potwierdzona end-to-end w klastrze Minikube — instalacja, konto `lab`, push, sync, self-heal, prune, revert.
- **Pułapki Argo CD:** Sekret repozytorium bez pola `url` pasującego do `repoURL` daje mylący błąd „SSH agent requested but SSH_AUTH_SOCK not-specified"; niepełne wpisy w `argocd-ssh-known-hosts-cm` kończą się „short read". Nie wchodzą do skryptu (ścieżka HTTPS ich nie dotyczy), zostają w notatkach.

## Kryteria odbioru

- `nix build path:.#docker-student` i `path:.#document` przechodzą.
- Brak przepełnień w PDF; wszystkie linki 200.
- Polecenia A–G wykonane na czystym klastrze, każda weryfikacja potwierdzona.
- Strona `website/content/zsr-lab.md` opisuje część IV.
