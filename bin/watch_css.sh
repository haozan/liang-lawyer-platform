#!/bin/bash
# CSS 守护进程 - 用 chokidar 风格的 Node 脚本持续监听
cd "$(dirname "$0")/.."
echo "[watch_css] Starting CSS watch daemon (loop mode)..."

rebuild() {
  echo "[watch_css] Rebuilding at $(date '+%H:%M:%S')..."
  node_modules/.bin/tailwindcss \
    -i ./app/assets/stylesheets/application.css \
    -o ./app/assets/builds/application.css 2>&1 | grep -v "caniuse-lite"
  node_modules/.bin/tailwindcss \
    -i ./app/assets/stylesheets/admin.css \
    -o ./app/assets/builds/admin.css 2>&1 | grep -v "caniuse-lite"
  echo "[watch_css] Done."
}

# Initial build
rebuild

# Watch using macOS FSEvents via a Node one-liner
node - <<'EOF'
const fs = require('fs');
const { execSync } = require('child_process');
const { spawnSync } = require('child_process');

let timer = null;
const DEBOUNCE_MS = 300;

const dirs = [
  'app/views',
  'app/assets/stylesheets',
  'app/javascript',
  'app/helpers',
  'app/controllers',
  'config/tailwind'
].filter(d => fs.existsSync(d));

function rebuild() {
  console.log('[watch_css] Rebuilding at', new Date().toLocaleTimeString());
  spawnSync('node_modules/.bin/tailwindcss', [
    '-i', './app/assets/stylesheets/application.css',
    '-o', './app/assets/builds/application.css'
  ], { stdio: 'inherit' });
  spawnSync('node_modules/.bin/tailwindcss', [
    '-i', './app/assets/stylesheets/admin.css',
    '-o', './app/assets/builds/admin.css'
  ], { stdio: 'inherit' });
}

function watchDir(dir) {
  fs.watch(dir, { recursive: true }, (event, filename) => {
    if (!filename) return;
    if (timer) clearTimeout(timer);
    timer = setTimeout(rebuild, DEBOUNCE_MS);
  });
}

dirs.forEach(watchDir);
console.log('[watch_css] Watching', dirs.join(', '), '...');
EOF
