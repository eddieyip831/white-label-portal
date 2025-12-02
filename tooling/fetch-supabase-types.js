// tooling/fetch-supabase-types.js
//
// Generate Supabase types WITHOUT supabase CLI
// Uses the REST metadata API (PostgREST / root endpoint)
import fs from 'fs';
import path from 'path';

// ========= CONFIG =========
// Reads from your existing .env.local
const envPath = path.resolve('apps/web/.env.local');
const outputPath = path.resolve('types/supabase.ts');

function parseEnv() {
  const raw = fs.readFileSync(envPath, 'utf8');
  const env = {};
  raw.split('\n').forEach((line) => {
    const [key, ...rest] = line.split('=');
    if (!key) return;
    env[key.trim()] = rest.join('=').trim().replace(/^"|"$/g, '');
  });
  return env;
}

async function fetchMetadata(url, anonKey) {
  const res = await fetch(`${url}/rest/v1/?apikey=${anonKey}`);
  if (!res.ok) {
    throw new Error(`Metadata fetch failed: ${res.status}`);
  }
  return res.json();
}

function generateTypeFile(metadata) {
  let out = `// Auto-generated without supabase CLI\n`;
  out += `// ${new Date().toISOString()}\n\n`;

  out += `export type Json = string | number | boolean | null | { [key: string]: Json } | Json[];\n\n`;

  out += `export interface Database {\n`;
  out += `  public: {\n`;
  out += `    Tables: {\n`;

  if (metadata.tables) {
    metadata.tables.forEach((t) => {
      out += `      "${t.name}": {\n`;
      out += `        Row: {\n`;
      t.columns.forEach((c) => {
        out += `          ${c.name}: ${pgToTs(c.type)};\n`;
      });
      out += `        }\n`;
      out += `      },\n`;
    });
  }

  out += `    }\n`;
  out += `    Functions: {\n`;

  if (metadata.functions) {
    metadata.functions.forEach((f) => {
      out += `      "${f.name}": {\n`;
      out += `        Args: any;\n`;
      out += `        Returns: any;\n`;
      out += `      },\n`;
    });
  }

  out += `    }\n`;
  out += `  }\n`;
  out += `}\n`;

  return out;
}

function pgToTs(pgType) {
  if (pgType.includes('text')) return 'string';
  if (pgType.includes('uuid')) return 'string';
  if (pgType.includes('timestamp')) return 'string';
  if (pgType.includes('bool')) return 'boolean';
  if (pgType.includes('int')) return 'number';
  if (pgType.includes('json')) return 'Json';
  return 'any';
}

async function main() {
  console.log('➡ Loading env...');
  const env = parseEnv();

  const url = env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anon) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY',
    );
  }

  console.log('➡ Fetching metadata...');
  const metadata = await fetchMetadata(url, anon);

  console.log('➡ Generating types...');
  const ts = generateTypeFile(metadata);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, ts);

  console.log('✔ Types written to:', outputPath);
}

main().catch((e) => {
  console.error('Error:', e);
  process.exit(1);
});
