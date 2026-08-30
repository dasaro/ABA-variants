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
// surface (the five concrete algebras; monoids sum/max/min; no count).

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

const SINGLE = {
    core: { base: 'core/base.lp' },
    // The framework preconditions, as a standalone pre-flight program. The playground runs it
    // through clingo-wasm before solving, so both boundaries check with the SAME file and the
    // same parser -- which is the only way pooled facts, multi-line facts, function terms and
    // block comments are handled identically on both sides.
    validate: { framework: 'validate.lp' }
};
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
    // Higher-order semantics are computed by post-filtering one of the four
    // candidate kernels.  Keep the candidate, filter and optional auxiliary
    // projection explicit so every runtime can reproduce the CLI pipeline.
    derivedSemantics: {
        preferred: 'admissible',
        grounded: 'complete',
        naive: 'cf',
        'semi-stable': 'complete',
        stage: 'cf',
        ideal: 'admissible',
        eager: 'complete'
    },
    semanticFilters: {
        preferred: 'subset_maximal_filter',
        grounded: 'subset_minimal_filter',
        naive: 'subset_maximal_filter',
        'semi-stable': 'range_maximal_filter',
        stage: 'range_maximal_filter',
        ideal: 'ideal_filter',
        eager: 'eager_filter'
    },
    semanticAuxiliaries: {
        'semi-stable': '_range',
        stage: '_range',
        eager: '_range'
    },
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

/**
 * Describe a semiring module FROM ITS SOURCE.
 *
 * Everything the playground UI needs about an algebra -- which way its polarity runs, whether
 * it carries a tunable constant, which delta policies it supports -- is already declared in the
 * .lp file. It used to be re-typed in the playground (POLARITY_BY_KEY, an `isLukasiewicz`
 * special case, a RECOMMENDED_BUDGET table and a prose table), so adding an algebra here meant
 * editing four JS files and an <option> list, and forgetting one produced a control that looked
 * right and computed the wrong thing. Extract it instead: the .lp file stays the single source.
 */
function describeSemiring(src, raw = src) {
    const one = (re) => { const m = src.match(re); return m ? m[1].trim() : null; };
    const oplus = one(/^\s*oplus\(([^)]+)\)\s*\./m);
    // The additive algebras (arctic, tropical) do not declare otimes: they compose the shared
    // _additive.lp skeleton, whose rule body IS the #sum. Read the skeleton they include rather
    // than reporting null, or the UI would have nothing to say about their conjunction.
    // A module supplying its OWN rule_deriv/4 is outside the shared skeletons; today that is
    // only Lukasiewicz, whose conjunction is its t-norm rather than plain addition.
    const ownRuleDeriv = /^rule_deriv\(/m.test(raw);
    const otimes = one(/^\s*otimes\(([^)]+)\)\s*\./m)
        || (ownRuleDeriv ? 'bounded +' : (/_additive\.lp/.test(raw) ? '+' : null))
        // An ALIAS shim (`#include "arctic.lp".`) declares nothing of its own; take the target's.
        || (raw.match(/#include\s+"(\w+)\.lp"/) && /#sum\s*\{/.test(src) ? '+' : null);
    return {
        oplus,
        otimes,
        oplusIdentity: one(/^\s*oplus_identity\(([^)]+)\)\s*\./m),
        otimesIdentity: one(/^\s*otimes_identity\(([^)]+)\)\s*\./m),
        // oplus = max means a bigger weight is a STRONGER objection ("higher"); oplus = min
        // means a smaller weight is a better-supported one ("lower"). Every bound direction in
        // the app follows from this, so it must not be re-derived by hand anywhere else.
        polarity: oplus === 'max' ? 'higher' : (oplus === 'min' ? 'lower' : null),
        // `#const k = 1000.` -> the UI must offer a control for k, and pass -c k.
        constants: [...src.matchAll(/^\s*#const\s+(\w+)\s*=\s*([^.]+)\./gm)]
            .map((m) => ({ name: m[1], default: Number(m[2].trim()) })),
        // FACTS only, at the start of a line. The resolved source also contains defaults/base.lp,
        // whose RULES mention semiring_default_weight(P, W) with an ASP variable -- scanning the
        // whole text harvested `P` and `policy` as if they were selectable policies.
        defaultPolicies: [...new Set(
            [...src.matchAll(/^semiring_default_weight\(\s*([a-z]\w*)\s*,[^)]*\)\s*\./gm)]
                .map((m) => m[1])
        )].sort()
    };
}

/** Every supported semantics uses the same external beta-sigma discard pipeline. */
function describeSemantics() {
    return { betaSigma: true };
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
const validate = loadSingle(SINGLE.validate);
const inputPolicy = JSON.parse(fs.readFileSync(path.join(WABA_ROOT, 'input-policy.json'), 'utf8'));
const sections = {};
for (const [name, rel] of Object.entries(DIRS)) sections[name] = discoverDir(rel);
const examples = discoverExamples();

// A semantics is offered when it has a module of its own, excluding the internal
// subset filters, plus the ones derived by post-filtering.
const SEMANTICS_MODULES = Object.keys(sections.semantics)
    .filter((k) => !k.startsWith('_') && !k.endsWith('_filter'));
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

// Per-module facts, read from the .lp sources so the playground never re-declares them.
const semiringInfo = {};
for (const [key, src] of Object.entries(sections.semiring)) {
    if (key.startsWith('_')) continue;      // shared skeletons, not selectable algebras
    const rawPath = path.join(WABA_ROOT, 'semiring', `${key}.lp`);
    const raw = fs.existsSync(rawPath) ? fs.readFileSync(rawPath, 'utf8') : src;
    semiringInfo[key] = describeSemiring(src, raw);
    // A true ALIAS is a file whose entire content is one #include -- it declares nothing of its
    // own. Matching any #include instead caught every module's shared skeleton, which would have
    // hidden all five real algebras from the UI.
    const body = raw.split('\n')
        .map((l) => l.replace(/%.*$/, '').trim())
        .filter(Boolean);
    const soleInclude = body.length === 1 && body[0].match(/^#include\s+"(\w+)\.lp"\.$/);
    semiringInfo[key].aliasOf = soleInclude ? soleInclude[1] : null;
}
const semanticsInfo = {};
for (const key of SUPPORTED_SEMANTICS) {
    semanticsInfo[key] = describeSemantics();
}

// A selectable algebra with no polarity would silently break every bound direction, so fail
// the sync rather than ship it.
for (const [key, info] of Object.entries(semiringInfo)) {
    if (!info.polarity) {
        throw new Error(`semiring/${key}.lp declares no oplus(max|min); polarity is undeterminable`);
    }
}

const metadata = {
    generatedFrom: 'ABA-variants/WABA',
    inputPolicy,
    semiringInfo,
    semanticsInfo,
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
    semanticFilters: POLICY.semanticFilters,
    semanticAuxiliaries: POLICY.semanticAuxiliaries,
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
    validate: {
${serializeSection(validate)}
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
