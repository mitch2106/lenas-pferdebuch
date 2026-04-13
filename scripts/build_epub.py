import zipfile
import os

epub_dir = r'C:\Users\m.heinl\lenas-pferdebuch\epub'
epub_path = r'C:\Users\m.heinl\lenas-pferdebuch\Lena_und_das_Geheimnis_der_silbernen_Hufspur.epub'

with zipfile.ZipFile(epub_path, 'w') as zf:
    # mimetype must be first entry, stored uncompressed, no extra field
    zf.write(os.path.join(epub_dir, 'mimetype'), 'mimetype', compress_type=zipfile.ZIP_STORED)

    # Add all other files with deflate compression
    for root, dirs, files in os.walk(epub_dir):
        dirs.sort()
        for f in sorted(files):
            full_path = os.path.join(root, f)
            arcname = os.path.relpath(full_path, epub_dir).replace(os.sep, '/')
            if arcname == 'mimetype':
                continue
            zf.write(full_path, arcname, compress_type=zipfile.ZIP_DEFLATED)

size = os.path.getsize(epub_path)
print(f'EPUB erfolgreich erstellt: {epub_path}')
print(f'Groesse: {size:,} Bytes ({size/1024/1024:.1f} MB)')
