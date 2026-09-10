---
name: italian-doc-scan
description: "Converts photographed/scanned Italian citizenship (jure sanguinis) case documents into transcribed-and-translated Word docs, logically renamed and grouped by generation, plus a case summary index — use for birth/death/marriage certificates, passports, naturalization papers, AIRE/consular records, etc."
---

# Italian Citizenship Document Conversion

## What this does and why

Someone building a jure sanguinis case has a pile of photographed documents —
often in Italian, Spanish, or English, spanning three or four generations —
and needs each one turned into something a case reviewer (or the applicant
themselves) can actually read and organize: a transcription in the original
language, an English translation, a sensible filename, and an index tying it
all together. Doing this by hand, one document at a time, is exactly the
kind of repetitive transcription + formatting work this skill exists to
speed up and make consistent.

## Workflow

For each batch of document images the user provides:

### 1. Identify each document

For every image, work out: document type (birth/death/marriage certificate,
passport, naturalization certificate, registry record, ID card, etc.),
the language it's written in, which family member(s) it's about, and the
date on the document (used for ordering within a generation).

### 2. Assign generational file numbers

Number files by how far back the person is in the citizenship chain, so
files sort with the Italian-born ancestor first:

- `1xx` — the italian-born ancestor's generation (e.g. grandfather)
- `2xx` — that ancestor's spouse's generation (e.g. grandmother)
- `3xx` — their child's generation (e.g. the applicant's parent)
- `4xx` — the applicant (self)

Within a block, order chronologically by the document's date (birth
certificate before marriage certificate before naturalization, etc.). This
is the default — apply it automatically without being asked, the same way
a paralegal organizing a case file would. If the family chain has an extra
generation (a great-grandparent) or a different shape, extend the same
logic (e.g. `0xx` for a generation further back) rather than forcing a
mismatched case into exactly four blocks — explain the adjustment briefly
to the user rather than silently picking one. A person who married into the
family isn't part of the bloodline, but their joint documents with the
blood relative still live in that relative's block (say so in the "Family
Line Represented" bullets so it's clear why they appear).

Example numbering from a real case:

```
101_DeFranco_Oreste_Estratto_di_Nascita_1910        (birth, 1910)
102_DeFranco_Oreste_Lofaro_Grazia_Marriage_Certificate_Pompei_1955
103_DeFranco_Oreste_Cedula_de_Identidad_Venezuela
104_DeFranco_Oreste_Italian_Passport_BioPage_G560507
106_DeFranco_Oreste_Acta_de_Defuncion_1989           (died 1989)

201_Lofaro_Grazia_Italian_Passport_BioPage_YB5244171

301_DeFranco_Eugenia_Acta_de_Nacimiento_1957         (born 1957)
304_Cangialosi_Salvatore_DeFranco_Eugenia_NYC_Marriage_Registration_1977
305_Cangialosi_Eugenia_Certificate_of_Naturalization_1999

401_Cangialosi_Anthony_Oreste_Certificate_of_Birth_1979
402_Cangialosi_Anthony_Oreste_US_Passport
```

Numbers within a block don't need to be contiguous — order chronologically
and leave gaps to insert a later-discovered document.

### 3. Rename the image and build a matching filename

Use `<NNN>_<Surname>_<GivenName(s)>_<DocumentType>_<Year>` (e.g.
`301_DeFranco_Eugenia_Acta_de_Nacimiento_1957`), keeping the source image's
original extension. The `.docx` gets the identical base name so the pair is
obviously linked in a file listing.

### 4. Transcribe and translate

Transcribe the document's text as separate lines/fields (not one run-on
paragraph), in the language it's actually written in — don't normalize
spelling or "clean up" the original. If a word or section is illegible,
write `[illegible]` rather than guessing, and add a short italic note in
the document rather than silently omitting it.

Add an "English Translation" section below the transcription for any
document that is not substantially in English. Skip the translation
section for documents already in English, and for documents that are
mostly English with only a few foreign-language field labels, a brief
translation note is enough — a full parallel translation would be
redundant.

### 5. Generate the Word documents with the bundled script

Don't write the `docx`-library boilerplate by hand — write the script
below to a scratch file once per session (e.g. `build_case.js`), then
drive it with small JSON specs instead of hand-writing `docx` calls for
every single document. First time in a scratch directory: `npm install
docx --no-save`.

```javascript
#!/usr/bin/env node
/**
 * Usage:
 *   node build_case.js docs <spec.json> <outdir>       — one .docx per document
 *   node build_case.js summary <spec.json> <outfile.docx>  — the case summary
 */
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, BorderStyle, ShadingType,
} = require("docx");

const LETTER_PORTRAIT = { width: 12240, height: 15840 };
const LETTER_LANDSCAPE = { width: 15840, height: 12240 };

function h1(text) { return new Paragraph({ text, heading: HeadingLevel.HEADING_1 }); }
function h2(text) { return new Paragraph({ text, heading: HeadingLevel.HEADING_2, spacing: { before: 240 } }); }
function h3(text) { return new Paragraph({ text, heading: HeadingLevel.HEADING_3, spacing: { before: 160 } }); }
function p(text) { return new Paragraph({ children: [new TextRun({ text })], spacing: { after: 120 } }); }
function italic(text) { return new Paragraph({ children: [new TextRun({ text, italics: true })], spacing: { after: 160 } }); }
function bullet(text) { return new Paragraph({ children: [new TextRun({ text })], bullet: { level: 0 }, spacing: { after: 60 } }); }
function hr() { return new Paragraph({ text: "", border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "999999" } }, spacing: { after: 200 } }); }

function metaTable(rows) {
  const colWidths = [2600, 6800];
  const trs = rows.map(([label, value]) => new TableRow({
    children: [
      new TableCell({ width: { size: colWidths[0], type: WidthType.DXA }, shading: { type: ShadingType.CLEAR, fill: "EFEFEF" }, children: [new Paragraph({ children: [new TextRun({ text: label, bold: true })] })] }),
      new TableCell({ width: { size: colWidths[1], type: WidthType.DXA }, children: [new Paragraph({ text: value || "—" })] }),
    ],
  }));
  return new Table({ width: { size: colWidths[0] + colWidths[1], type: WidthType.DXA }, columnWidths: colWidths, rows: trs });
}

function buildDoc(spec) {
  const children = [h1(spec.title), p(`Source image file: ${spec.sourceFile}`), hr(), h2("Document Metadata"), metaTable(spec.meta), new Paragraph({ text: "", spacing: { after: 200 } })];
  if (spec.note) children.push(italic(spec.note));
  children.push(h2(spec.originalHeading || "Extracted Text"));
  (spec.originalParas || []).forEach((t) => children.push(p(t)));
  if (spec.translationParas && spec.translationParas.length) {
    children.push(hr(), h2(spec.translationHeading || "English Translation"));
    spec.translationParas.forEach((t) => children.push(p(t)));
  }
  return new Document({ sections: [{ properties: { page: { size: LETTER_PORTRAIT } }, children }] });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: { size: opts.width, type: WidthType.DXA },
    shading: opts.header ? { type: ShadingType.CLEAR, fill: "D9E2F3" } : (opts.fill ? { type: ShadingType.CLEAR, fill: opts.fill } : undefined),
    children: [new Paragraph({ children: [new TextRun({ text: String(text), bold: !!opts.header, size: 18 })] })],
  });
}
const SUMMARY_COLS = [700, 2100, 1500, 1300, 1300, 900, 3660];
const SUMMARY_HEADERS = ["#", "Document", "Type", "Person(s)", "Date", "Language", "Image / Word Files"];
function summaryHeaderRow() { return new TableRow({ tableHeader: true, children: SUMMARY_HEADERS.map((t, i) => cell(t, { width: SUMMARY_COLS[i], header: true })) }); }
function groupTable(rows, fill) {
  const tableRows = [summaryHeaderRow()].concat(rows.map((r) => new TableRow({
    children: [0, 1, 2, 3, 4, 5].map((i) => cell(r[i], { width: SUMMARY_COLS[i], fill })).concat([cell(r[6] + ".jpg / .docx", { width: SUMMARY_COLS[6], fill })]),
  })));
  return new Table({ width: { size: SUMMARY_COLS.reduce((a, b) => a + b, 0), type: WidthType.DXA }, columnWidths: SUMMARY_COLS, rows: tableRows });
}

function buildSummaryDoc(spec) {
  const children = [h1(spec.title)];
  (spec.intro || []).forEach((t) => children.push(p(t)));
  children.push(hr());
  if (spec.familyBullets && spec.familyBullets.length) {
    children.push(h2("Family Line Represented"));
    spec.familyBullets.forEach((t) => children.push(bullet(t)));
    children.push(hr());
  }
  children.push(h2("Document Index"));
  (spec.groups || []).forEach((g) => {
    if (g.heading) children.push(h3(g.heading));
    children.push(groupTable(g.rows, g.fill || "D9E2F3"));
    children.push(new Paragraph({ text: "", spacing: { after: 160 } }));
  });
  if (spec.notes && spec.notes.length) {
    children.push(hr(), h2("Notes"));
    spec.notes.forEach((t) => children.push(bullet(t)));
  }
  return new Document({ sections: [{ properties: { page: { size: LETTER_LANDSCAPE, orientation: "landscape" } }, children }] });
}

async function writeDoc(doc, outPath) {
  const buf = await Packer.toBuffer(doc);
  fs.writeFileSync(outPath, buf);
}

(async () => {
  const [, , mode, specPath, out] = process.argv;
  if (!["docs", "summary"].includes(mode) || !specPath || !out) {
    console.error("Usage: node build_case.js docs <spec.json> <outdir>  |  node build_case.js summary <spec.json> <outfile.docx>");
    process.exit(1);
  }
  const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
  if (mode === "docs") {
    fs.mkdirSync(out, { recursive: true });
    for (const d of spec.documents) {
      const outPath = path.join(out, `${d.file}.docx`);
      await writeDoc(buildDoc(d), outPath);
      console.log("wrote", outPath);
    }
  } else {
    await writeDoc(buildSummaryDoc(spec), out);
    console.log("wrote", out);
  }
})();
```

**`docs` spec shape** (one entry per document; omit `translationHeading`/
`translationParas` entirely for a document already in English):

```json
{
  "documents": [
    {
      "file": "301_DeFranco_Eugenia_Acta_de_Nacimiento_1957",
      "title": "Birth Certificate (Acta de Nacimiento) — Eugenia Adelina De Franco",
      "sourceFile": "301_DeFranco_Eugenia_Acta_de_Nacimiento_1957.jpg",
      "meta": [["Document Type", "Civil birth record"], ["Person", "Eugenia Adelina De Franco"], ["Language", "Spanish"]],
      "originalHeading": "Extracted Text",
      "originalParas": ["República de Venezuela — Acta de Nacimiento", "Nombre: Eugenia Adelina De Franco", "..."],
      "translationHeading": "English Translation",
      "translationParas": ["Republic of Venezuela — Birth Certificate", "Name: Eugenia Adelina De Franco", "..."],
      "note": "Optional italic disclaimer, e.g. about an illegible section."
    }
  ]
}
```

**`summary` spec shape** — one group per generation (each `rows` entry is
`[number, document name, type, person(s), date, language, baseFilename]`;
suggested `fill` colors: `FCE4D6` peach 1xx, `E2EFDA` green 2xx, `DDEBF7`
blue 3xx, `FFF2CC` yellow 4xx — omit `heading` on a group for a flat,
non-generational index):

```json
{
  "title": "Italian Citizenship Documents — Summary",
  "intro": ["This summary indexes the source documents...", "Files are numbered by generation..."],
  "familyBullets": ["Oreste Guglielmo De Franco (Grandfather, 1xx) — born 19 May 1910...", "..."],
  "groups": [
    { "heading": "1xx — Grandfather: Oreste Guglielmo De Franco", "fill": "FCE4D6",
      "rows": [["101", "Birth Certificate Extract", "Civil birth record", "Oreste Guglielmo De Franco", "Born 19 May 1910", "Italian", "101_DeFranco_Oreste_Estratto_di_Nascita_1910"]] }
  ],
  "notes": ["Each Word document contains the text transcribed... plus an English translation for non-English documents.", "These transcriptions/translations are for personal reference and case organization; they are not certified. Official submissions may still require certified translations."]
}
```

If a layout is needed that the script doesn't support, extend the same
functions rather than writing a parallel implementation from scratch. For
general `docx`-library mechanics and gotchas beyond what's used here (page
size, table column widths, shading), defer to a project's own `docx` skill
if one is available in the session.

### 6. Always include the translation disclaimer

In the summary's Notes section, always state plainly that these
transcriptions/translations are for personal reference and case
organization, not certified — official submissions may still require
certified translations.

### 7. Updating an existing case

When adding documents to a case already converted, or renumbering it,
regenerate every document whose number or "Source image file" reference
changed — not just the new ones. A summary table row or a transcription
doc that still points at an old filename is worse than not updating it at
all. Leave everything else untouched.

### 8. Verify before delivering

Convert at least the summary doc (and spot-check one or two transcription
docs) to PDF and view a page to confirm it actually renders — table
widths, page orientation, and translation sections have all silently
broken before. If a `docx`-related skill is available in the session, its
office-conversion helper script typically does the PDF conversion; then
render one page as an image and look at it before calling the work done.

### 9. Writing to the destination the user named

If the destination is a folder on the user's own computer reached through
a device bridge, follow the session's normal guidance for writing there.
One thing worth knowing specifically for this kind of task: if a shell on
the user's computer can't mount the destination folder even though direct
file-write tools against that folder work fine, don't keep retrying the
mount — fall back to building the files locally and writing them into the
folder via whatever direct-write mechanism is available. That fallback
usually can't delete or rename in place, so a "rename" under it means the
new-named files get added while old-named ones remain — say so plainly
when delivering the result, and if asked to clean up later, give the exact
list of now-superseded filenames rather than guessing.