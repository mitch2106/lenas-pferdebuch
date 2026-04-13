import { createWriteStream, readFileSync, readdirSync, statSync } from 'fs';
import { join, relative } from 'path';
import { Writable } from 'stream';
import { Buffer } from 'buffer';
import zlib from 'zlib';

const epubDir = 'C:/Users/m.heinl/lenas-pferdebuch/epub';
const epubPath = 'C:/Users/m.heinl/lenas-pferdebuch/Lena_und_das_Geheimnis_der_silbernen_Hufspur.epub';

// Minimal ZIP file creator
class ZipWriter {
  constructor(outputPath) {
    this.entries = [];
    this.offset = 0;
    this.buf = [];
  }

  addFile(arcname, data, compress = true) {
    const entry = { arcname, offset: this.offset };
    const nameBuffer = Buffer.from(arcname, 'utf8');

    let compressedData = data;
    let method = 0; // stored

    if (compress) {
      const deflated = zlib.deflateRawSync(data);
      if (deflated.length < data.length) {
        compressedData = deflated;
        method = 8; // deflate
      }
    }

    entry.method = method;
    entry.crc = crc32(data);
    entry.compressedSize = compressedData.length;
    entry.uncompressedSize = data.length;

    // Local file header
    const localHeader = Buffer.alloc(30 + nameBuffer.length);
    localHeader.writeUInt32LE(0x04034b50, 0); // signature
    localHeader.writeUInt16LE(20, 4);  // version needed
    localHeader.writeUInt16LE(0, 6);   // flags
    localHeader.writeUInt16LE(method, 8); // compression
    localHeader.writeUInt16LE(0, 10);  // mod time
    localHeader.writeUInt16LE(0, 12);  // mod date
    localHeader.writeUInt32LE(entry.crc, 14);
    localHeader.writeUInt32LE(entry.compressedSize, 18);
    localHeader.writeUInt32LE(entry.uncompressedSize, 22);
    localHeader.writeUInt16LE(nameBuffer.length, 26);
    localHeader.writeUInt16LE(0, 28);  // extra field length
    nameBuffer.copy(localHeader, 30);

    this.buf.push(localHeader);
    this.buf.push(compressedData);
    this.offset += localHeader.length + compressedData.length;

    entry.nameBuffer = nameBuffer;
    this.entries.push(entry);
  }

  finalize() {
    const centralDirStart = this.offset;

    for (const entry of this.entries) {
      const cdEntry = Buffer.alloc(46 + entry.nameBuffer.length);
      cdEntry.writeUInt32LE(0x02014b50, 0); // signature
      cdEntry.writeUInt16LE(20, 4);  // version made by
      cdEntry.writeUInt16LE(20, 6);  // version needed
      cdEntry.writeUInt16LE(0, 8);   // flags
      cdEntry.writeUInt16LE(entry.method, 10);
      cdEntry.writeUInt16LE(0, 12);  // mod time
      cdEntry.writeUInt16LE(0, 14);  // mod date
      cdEntry.writeUInt32LE(entry.crc, 16);
      cdEntry.writeUInt32LE(entry.compressedSize, 20);
      cdEntry.writeUInt32LE(entry.uncompressedSize, 24);
      cdEntry.writeUInt16LE(entry.nameBuffer.length, 28);
      cdEntry.writeUInt16LE(0, 30);  // extra field
      cdEntry.writeUInt16LE(0, 32);  // comment
      cdEntry.writeUInt16LE(0, 34);  // disk start
      cdEntry.writeUInt16LE(0, 36);  // internal attrs
      cdEntry.writeUInt32LE(0, 38);  // external attrs
      cdEntry.writeUInt32LE(entry.offset, 42);
      entry.nameBuffer.copy(cdEntry, 46);

      this.buf.push(cdEntry);
      this.offset += cdEntry.length;
    }

    const centralDirSize = this.offset - centralDirStart;

    // End of central directory
    const eocd = Buffer.alloc(22);
    eocd.writeUInt32LE(0x06054b50, 0);
    eocd.writeUInt16LE(0, 4);  // disk number
    eocd.writeUInt16LE(0, 6);  // disk with cd
    eocd.writeUInt16LE(this.entries.length, 8);
    eocd.writeUInt16LE(this.entries.length, 10);
    eocd.writeUInt32LE(centralDirSize, 12);
    eocd.writeUInt32LE(centralDirStart, 16);
    eocd.writeUInt16LE(0, 20); // comment
    this.buf.push(eocd);

    return Buffer.concat(this.buf);
  }
}

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xEDB88320 : 0);
    }
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function walkDir(dir) {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      results.push(...walkDir(full));
    } else {
      results.push(full);
    }
  }
  return results.sort();
}

// Build EPUB
const zip = new ZipWriter();

// mimetype first, uncompressed
zip.addFile('mimetype', readFileSync(join(epubDir, 'mimetype')), false);

// All other files
const allFiles = walkDir(epubDir);
for (const f of allFiles) {
  const arcname = relative(epubDir, f).replace(/\\/g, '/');
  if (arcname === 'mimetype') continue;
  const data = readFileSync(f);
  zip.addFile(arcname, data, true);
}

const result = zip.finalize();
const { writeFileSync } = await import('fs');
writeFileSync(epubPath, result);

console.log(`EPUB erstellt: ${epubPath}`);
console.log(`Groesse: ${result.length.toLocaleString()} Bytes (${(result.length / 1024 / 1024).toFixed(1)} MB)`);
