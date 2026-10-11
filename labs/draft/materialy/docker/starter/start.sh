#!/usr/bin/env bash
set -euo pipefail

# Przy kolejnym uruchomieniu należy zachować te same nazwy zasobów.
docker network inspect zsr-net >/dev/null 2>&1 || docker network create zsr-net
docker volume inspect zsr-pgdata >/dev/null 2>&1 || docker volume create zsr-pgdata
docker volume inspect zsr-uploads >/dev/null 2>&1 || docker volume create zsr-uploads

# Należy zapisać polecenie uruchomienia PostgreSQL z zadania E.

# Należy poczekać na gotowość bazy.

# Należy zapisać polecenie uruchomienia Redmine z zadania F.
