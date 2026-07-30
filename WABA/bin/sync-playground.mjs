#!/usr/bin/env node
//
// sync-playground.mjs — regenerate the web playground's `waba-modules.js` bundle
// from the CANONICAL WABA modules in this repo (the source of truth).
//
// The browser playground (https://github.com/dasaro/waba-playground) runs the
// same `.lp` logic compiled into a single `waba-modules.js`. This tool keeps
// that bundle in sync by AUTO-DISCOVERING the module set from the WABA tree, so
// adding/removing a semiring, monoid, semantics or example propagates with no
// hand-maintained manifest to go stale.
//
// Usage:
//   node WABA/bin/sync-playground.mjs <path/to/waba-playground/waba-modules.js>
//   WABA_ROOT=/other/WABA node WABA/bin/sync-playground.mjs out.js
//
// NOTE: this only regenerates the .lp bundle + its metadata. The playground's
// JS/UI (config-service.js, index.html, ...) must independently offer the same
// surface (semiring families godel/tropical; monoids sum/max/min; no count).

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// WABA tree = parent of bin/ (override with WABA_ROOT).
const WABA_ROOT = process.env.WABA_ROOT || path.join(__dirname, '..');
const OUTPUT_FILE = process.argv[2];

if (!OUTPUT_FILE) {
    console.error('usage: node sync-playground.mjs <output waba-modules.js>  [WABA_ROOT=...]');
    process.exit(2);
}

const SINGLE = { core: { base: 'core/base.lp' } };
const DIRS = {
    semiring: 'semiring',
    defaults: 'defaults',
    monoid: 'monoid',
    optimize: 'optimize',
    constraint: 'constraint',
    filter: 'filter',
    semantics: 'semantics'
};

// Structural policy mirroring WABA/bin/waba (the supported CLI surface).
// Only the *shape* lives here; the module SET is discovered from disk.
const POLICY = {
    semiringFamilies: ['godel', 'tropical'],
    polarities: ['higher', 'lower'],
    canonicalSemiring: {
        godel: { higher: 'godel', lower: 'bottleneck_cost' },
        tropical: { higher: 'arctic', lower: 'tropical' }
    },
    aliases: {
        godel_low: { family: 'godel', polarity: 'lower' },
        tropical_high: { family: 'tropical', polarity: 'higher' }
    },
    // Semantics that exist as their own module are discovered; these two are computed by
    // post-filtering another semantics and so have no module of their own.
    derivedSemantics: { preferred: 'admissible' },
    budgetSide: { sum: 'ub', max: 'ub', min: 'lb' }
};

function escapeTemplateLiteral(content) {
    return content.replace(/\\/g, '\\\\').replace(/`/g, '\\`').replace(/\$/g, '\\$');
}

function resolveIncludes(content, basedir, visited = new Set()) {
    const includePattern = /#include\s+"([^"]+)"\.?/g;
    return content.replace(includePattern, (match, relativePath) => {
        const includePath = path.resolve(basedir, relativePath);
        if (visited.has(includePath)) throw new Error(`Circular include at ${includePath}`);
        if (!fs.existsSync(includePath)) throw new Error(`Missing include ${relativePath} from ${basedir}`);
        visited.add(includePath);
        return resolveIncludes(fs.readFileSync(includePath, 'utf8'), path.dirname(includePath), visited);
    });
}

function readModule(relativePath) {
    const abs = path.join(WABA_ROOT, relativePath);
    if (!fs.existsSync(abs)) throw new Error(`Required module not found: ${relativePath}`);
    return resolveIncludes(fs.readFileSync(abs, 'utf8'), path.dirname(abs), new Set([abs]));
}

function discoverDir(relDir) {
    const absDir = path.join(WABA_ROOT, relDir);
    if (!fs.existsSync(absDir)) throw new Error(`Required directory not found: ${relDir}`);
    const result = {};
    for (const file of fs.readdirSync(absDir).sort()) {
        if (!file.endsWith('.lp')) continue;
        result[path.basename(file, '.lp')] = readModule(path.join(relDir, file));
    }
    return result;
}

function loadSingle(entries) {
    const result = {};
    for (const [key, rel] of Object.entries(entries)) result[key] = readModule(rel);
    return result;
}

function discoverExamples() {
    const root = path.join(WABA_ROOT, 'examples');
    const result = {};
    const walk = (dir) => {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })
            .sort((a, b) => a.name.localeCompare(b.name))) {
            const full = path.join(dir, entry.name);
            if (entry.isDirectory()) walk(full);
            else if (entry.name.endsWith('.lp')) {
                result[path.basename(entry.name, '.lp')] =
                    resolveIncludes(fs.readFileSync(full, 'utf8'), path.dirname(full), new Set([full]));
            }
        }
    };
    if (fs.existsSync(root)) walk(root);
    return result;
}

function serializeSection(sectionObject, indent = '        ') {
    return Object.entries(sectionObject)
        .map(([key, value]) => `${indent}${JSON.stringify(key)}: \`${escapeTemplateLiteral(value)}\``)
        .join(',\n');
}

function serializeMetadata(metadata) {
    return JSON.stringify(metadata, null, 4)
        .split('\n')
        .map((line, index) => (index === 0 ? line : `    ${line}`))
        .join('\n');
}

console.log(`Syncing WABA modules from ${WABA_ROOT}`);

const core = loadSingle(SINGLE.core);
const sections = {};
for (const [name, rel] of Object.entries(DIRS)) sections[name] = discoverDir(rel);
const examples = discoverExamples();

// A semantics is offered when it has a module of its own, excluding the internal
// subset filters, plus the ones derived by post-filtering.
const SEMANTICS_MODULES = Object.keys(sections.semantics).filter((k) => !k.endsWith('_filter'));
const SUPPORTED_SEMANTICS = [
    ...SEMANTICS_MODULES,
    ...Object.keys(POLICY.derivedSemantics).filter((k) => !SEMANTICS_MODULES.includes(k))
];

const monoids = Object.keys(sections.monoid);
const optimizations = Object.keys(sections.optimize).filter((k) => k === 'minimize' || k === 'maximize');
const objectives = [];
for (const m of monoids) for (const dir of ['min', 'max']) objectives.push(`${m}-${dir}`);
const supportedBudgetPairs = monoids
    .filter((m) => POLICY.budgetSide[m])
    .map((m) => ({ monoid: m, budgetMode: POLICY.budgetSide[m] }));

const metadata = {
    generatedFrom: 'ABA-variants/WABA',
    semiringFamilies: POLICY.semiringFamilies,
    polarities: POLICY.polarities,
    // `_`-prefixed modules are shared skeletons, not selectable algebras.
    supportedSemiringKeys: Object.keys(sections.semiring).filter((k) => !k.startsWith('_')),
    defaults: Object.keys(sections.defaults),
    monoids,
    optimizations,
    objectives,
    budgetModes: ['none', 'ub', 'lb'],
    supportedSemantics: SUPPORTED_SEMANTICS,
    postFilteredSemantics: Object.keys(POLICY.derivedSemantics),
    derivedSemantics: POLICY.derivedSemantics,
    canonicalSemiring: POLICY.canonicalSemiring,
    aliases: POLICY.aliases,
    supportedBudgetPairs
};

const output = `// AUTO-GENERATED by WABA/bin/sync-playground.mjs
// DO NOT EDIT MANUALLY
// Source of truth: ${metadata.generatedFrom}

export const wabaModules = {
    core: {
${serializeSection(core)}
    },
    semiring: {
${serializeSection(sections.semiring)}
    },
    defaults: {
${serializeSection(sections.defaults)}
    },
    monoid: {
${serializeSection(sections.monoid)}
    },
    optimize: {
${serializeSection(sections.optimize)}
    },
    constraint: {
${serializeSection(sections.constraint)}
    },
    filter: {
${serializeSection(sections.filter)}
    },
    semantics: {
${serializeSection(sections.semantics)}
    },
    examples: {
${serializeSection(examples)}
    },
    metadata: ${serializeMetadata(metadata)}
};
`;

fs.mkdirSync(path.dirname(path.resolve(OUTPUT_FILE)), { recursive: true });
fs.writeFileSync(OUTPUT_FILE, output, 'utf8');

console.log(`Generated ${OUTPUT_FILE}`);
console.log(`  semirings: ${metadata.supportedSemiringKeys.join(', ')}`);
console.log(`  monoids:   ${metadata.monoids.join(', ')}`);
console.log(`  objectives:${metadata.objectives.join(', ')}`);
console.log(`  semantics: ${Object.keys(sections.semantics).join(', ')}`);
console.log(`  examples:  ${Object.keys(examples).length} (${Object.keys(examples).join(', ')})`);
