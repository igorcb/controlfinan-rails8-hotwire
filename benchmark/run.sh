#!/usr/bin/env bash
# ControlFinan benchmark: Rails 8 + Hotwire (this repo) x Django x Laravel (Octane) x Go x Java x Rust.
# Usage: ./benchmark/run.sh [apps...] (default: rails django laravel go java rust)
# Needs this repo's dev database running (docker compose up db), which provides the shared data
# (benchmark@exemplo.com and its entries), and the other apps cloned next to this repo:
# ../controlfinan-django, ../controlfinan-laravel, ../controlfinan-go, ../controlfinan-java and ../controlfinan-rust.
set -euo pipefail
cd "$(dirname "$0")"
RAILS_APP="$(cd .. && pwd)"
DJANGO_APP="$(cd ../../controlfinan-django && pwd)"
LARAVEL_APP="$(cd ../../controlfinan-laravel && pwd)"
JAVA_APP="$(cd ../../controlfinan-java && pwd)"
GO_APP="$(cd ../../controlfinan-go && pwd)"
RUST_APP="$(cd ../../controlfinan-rust && pwd)"
export RAILS_APP DJANGO_APP LARAVEL_APP JAVA_APP GO_APP RUST_APP
RAILS_MASTER_KEY="$(cat "$RAILS_APP/config/master.key")"
export RAILS_MASTER_KEY
APPS=("${@:-rails django laravel go java rust}")
read -r -a APPS <<< "${APPS[*]}"
RESULTS=results
mkdir -p "$RESULTS"
compose() { docker compose -p cfbench "$@"; }

echo "== build"
compose build "${APPS[@]}" >/dev/null

echo "== shared data (users + current_accounts from the Rails dev database)"
docker exec controlfinan-rails8-hotwire-db-1 pg_dump -U app --data-only -t users -t current_accounts app_development > "$RESULTS/data.sql"

measure_boot() { # $1 service, $2 port -> seconds until /up answers 200
  local start end
  start=$(date +%s.%N)
  compose up -d "$1" >/dev/null 2>&1
  until curl -fs "http://localhost:$2/up" >/dev/null 2>&1; do sleep 0.2; done
  end=$(date +%s.%N)
  LC_ALL=C printf "%.3f" "$(echo "$end - $start" | bc)"
}

sample_stats() { # $1 container, $2 output file; runs until killed
  while true; do docker stats --no-stream --format '{{.CPUPerc}};{{.MemUsage}}' "$1" >> "$2" 2>/dev/null; done
}

for app in "${APPS[@]}"; do
  case $app in
    rails) port=3101; inner=3000; dbname=app_production ;;
    django) port=8101; inner=8000; dbname=controlfinan_django ;;
    laravel) port=8102; inner=8000; dbname=controlfinan_laravel ;;
    go) port=8104; inner=8000; dbname=controlfinan_go ;;
    java) port=8105; inner=8000; dbname=controlfinan_java ;;
    rust) port=8106; inner=8000; dbname=controlfinan_rust ;;
  esac
  db="$app-db"
  echo "== $app"
  rm -f "$RESULTS/$app-"*
  compose up -d "$db" >/dev/null 2>&1
  until compose exec -T "$db" pg_isready -U app >/dev/null 2>&1; do sleep 0.5; done
  sleep 2
  boot=$(measure_boot "$app" "$port")
  compose exec -T "$db" psql -U app -d "$dbname" -q -c "SET session_replication_role = replica;" -f - < "$RESULTS/data.sql" >/dev/null
  # Fresh statistics, so the first page measured does not run with plans made for empty tables.
  compose exec -T "$db" psql -U app -d "$dbname" -q -c "ANALYZE;" >/dev/null
  compose restart "$app" >/dev/null 2>&1   # fresh processes with the data loaded
  until curl -fs "http://localhost:$port/up" >/dev/null 2>&1; do sleep 0.2; done
  sleep 3
  container=$(compose ps -q "$app")
  db_container=$(compose ps -q "$db")
  idle=$(docker stats --no-stream --format '{{.MemUsage}}' "$container" | cut -d/ -f1)
  image=$(docker image inspect "bench-$app" --format '{{.Size}}')
  echo "{\"boot_seconds\": $boot, \"idle_memory\": \"$idle\", \"image_bytes\": $image}" > "$RESULTS/$app-meta.json"
  echo "   boot ${boot}s, idle memory $idle"
  # Warm-up pass (not measured): 20 s on every page, so runtimes with a JIT (YJIT, JVM) reach steady state.
  for page in lista dia dashboard json criar; do
    compose run --rm -T --user "$(id -u):$(id -g)" -e BASE="http://$app:$inner" -e PAGE="$page" -e OUT="/results/warmup.json" \
      -e WARMUP=5s -e LOAD=15s k6 run --quiet /scripts/scenario.js > /dev/null 2>&1 || true
  done
  rm -f "$RESULTS/warmup.json"
  # Remove the entries created by the warm-up POSTs (dated 2031-01-01), so every app measures the same data.
  # VACUUM clears the deleted rows; without it the faster apps (which create more rows) would scan more dead rows.
  compose exec -T "$db" psql -U app -d "$dbname" -q -c "DELETE FROM current_accounts WHERE date_ocurrence = '2031-01-01'" >/dev/null
  compose exec -T "$db" psql -U app -d "$dbname" -q -c "VACUUM FULL ANALYZE current_accounts" >/dev/null
  echo "   rows after warm-up cleanup: $(compose exec -T "$db" psql -U app -d "$dbname" -tAc "SELECT count(*) FROM current_accounts")"
  echo "   warm-up done"
  for page in lista dia dashboard json criar; do
    sample_stats "$container" "$RESULTS/$app-$page-stats.txt" & sampler=$!
    sample_stats "$db_container" "$RESULTS/$app-$page-dbstats.txt" & db_sampler=$!
    compose run --rm -T --user "$(id -u):$(id -g)" -e BASE="http://$app:$inner" -e PAGE="$page" -e OUT="/results/$app-$page.json" \
      k6 run --quiet /scripts/scenario.js > "$RESULTS/$app-$page-k6.log" 2>&1 || echo "   (k6 returned an error for $page, see $RESULTS/$app-$page-k6.log)"
    kill "$sampler" "$db_sampler" 2>/dev/null; wait "$sampler" "$db_sampler" 2>/dev/null || true
    echo "   $page done"
  done
  compose stop "$app" "$db" >/dev/null 2>&1
  compose rm -fsv "$db" >/dev/null 2>&1
done

compose down -v >/dev/null 2>&1
python3 report.py "$RESULTS" | tee "$RESULTS/RESULTS.md"
