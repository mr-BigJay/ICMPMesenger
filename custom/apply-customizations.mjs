#!/usr/bin/env node
/**
 * Apply ICMPMesenger custom branding onto a cloned XuanIM source tree.
 * Used by GitHub Actions — no local dev tools required on your PC.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const xuanimRoot = process.env.XUANIM_SRC
  ? path.resolve(process.env.XUANIM_SRC)
  : path.join(repoRoot, 'xuanim-src');
const xxcRoot = path.join(xuanimRoot, 'xxc');
const brandingDir = path.join(__dirname, 'branding');

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 4)}\n`, 'utf8');
}

function mergeJson(base, overrides) {
  return { ...base, ...overrides };
}

function assertExists(dir, label) {
  if (!fs.existsSync(dir)) {
    console.error(`Missing ${label}: ${dir}`);
    process.exit(1);
  }
}

function copyDirRecursive(srcDir, dstDir) {
  fs.mkdirSync(dstDir, { recursive: true });
  for (const entry of fs.readdirSync(srcDir, { withFileTypes: true })) {
    const srcPath = path.join(srcDir, entry.name);
    const dstPath = path.join(dstDir, entry.name);
    if (entry.isDirectory()) {
      copyDirRecursive(srcPath, dstPath);
    } else {
      fs.copyFileSync(srcPath, dstPath);
    }
  }
}

assertExists(xxcRoot, 'XuanIM client (xxc)');

console.log('Applying customizations to:', xxcRoot);

// 1) package.json — app name / product name
const pkgPath = path.join(xxcRoot, 'package.json');
const pkg = readJson(pkgPath);
const pkgOverrides = readJson(path.join(brandingDir, 'package.overrides.json'));
writeJson(pkgPath, mergeJson(pkg, pkgOverrides));
console.log('  Updated xxc/package.json → productName:', pkgOverrides.productName);

// 2) Default language → English
const langConfigSrc = path.join(brandingDir, 'lang-config.ts');
const langConfigDst = path.join(xxcRoot, 'app/config/lang.ts');
fs.copyFileSync(langConfigSrc, langConfigDst);
console.log('  Updated app/config/lang.ts → DEFAULT: fa-ir (Persian + English only)');

// 3) English string overrides (branding labels)
const enPath = path.join(xxcRoot, 'app/lang/en.json');
const en = readJson(enPath);
const enOverrides = readJson(path.join(brandingDir, 'en-overrides.json'));
writeJson(enPath, mergeJson(en, enOverrides));
console.log('  Merged en-overrides.json into app/lang/en.json');

// 4) Persian language — fa-ir.json + client patches, remove Chinese
const xxcPatchesDir = path.join(brandingDir, 'xxc-patches', 'app');
if (fs.existsSync(xxcPatchesDir)) {
  copyDirRecursive(xxcPatchesDir, path.join(xxcRoot, 'app'));
  console.log('  Applied xxc-patches (fa-ir, constants, lang core, RTL)');
}
for (const removed of ['zh-cn.json', 'zh-tw.json']) {
  const langFile = path.join(xxcRoot, 'app/lang', removed);
  if (fs.existsSync(langFile)) {
    fs.unlinkSync(langFile);
    console.log('  Removed app/lang/' + removed);
  }
}
const faPath = path.join(xxcRoot, 'app/lang/fa-ir.json');
if (fs.existsSync(faPath)) {
  const fa = readJson(faPath);
  const faOverrides = readJson(path.join(brandingDir, 'fa-overrides.json'));
  writeJson(faPath, mergeJson(fa, faOverrides));
  console.log('  Merged fa-overrides.json into app/lang/fa-ir.json');
}

// 5) Windows installer file name
const packageConfigPath = path.join(xxcRoot, 'build/package-config.json');
if (fs.existsSync(packageConfigPath)) {
  const packageConfig = readJson(packageConfigPath);
  packageConfig.winArtifactName = 'JayMessenger-Setup-${version}.${ext}';
  packageConfig.artifactName = 'JayMessenger-${version}-${os}-${arch}.${ext}';
  writeJson(packageConfigPath, packageConfig);
  console.log('  Updated build/package-config.json artifact names');
}

console.log('Customization complete.');
