#!/bin/sh
# Run CollateX on loopback :17106 and nginx framer on :17105.
set -eu

java -jar /collatex-tools.jar --http --port 17106 &
JAVA_PID=$!
NGINX_PID=

cleanup() {
  kill -TERM "$JAVA_PID" 2>/dev/null || true
  if [ -n "${NGINX_PID}" ]; then
    kill -TERM "$NGINX_PID" 2>/dev/null || true
    wait "$NGINX_PID" 2>/dev/null || true
  fi
  wait "$JAVA_PID" 2>/dev/null || true
}
trap cleanup TERM INT EXIT

# Wait until CollateX is LISTENing on 17106 before starting nginx.
# 17106 decimal == 0x42D2 in /proc/net/tcp.
i=0
while [ "$i" -lt 60 ]; do
  if awk 'index($2,":42D2") && $4=="0A" {found=1} END {exit found?0:1}' /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
    break
  fi
  i=$((i + 1))
  sleep 1
done
if [ "$i" -ge 60 ]; then
  echo "collatex failed to listen on 17106 within 60s" >&2
  exit 1
fi

nginx -g 'daemon off;' &
NGINX_PID=$!

# Exit if either child dies.
while kill -0 "$JAVA_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do
  sleep 1
done
exit 1
