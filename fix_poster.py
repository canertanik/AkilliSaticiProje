import re
import io

file_path = r'C:\Users\caner44\Desktop\Akıllı Satıcı - Proje Posteri_sonduzenli.html'

# Read as windows-1254 (or utf-8 with replacement if it's mixed)
try:
    with io.open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
except UnicodeDecodeError:
    with io.open(file_path, 'r', encoding='windows-1254') as f:
        content = f.read()

# Fix Turkish characters if they are garbled
content = content.replace('GeliYtirici:', 'Geliştirici:')
content = content.replace('DanYman:', 'Danışman:')
content = content.replace('Sleyman Gkhan Takn', 'Süleyman Gökhan Taşkın')
content = content.replace('Gelitirici:', 'Geliştirici:')
content = content.replace('Danman:', 'Danışman:')
content = content.replace('SǬleyman Gkhan TaYkn', 'Süleyman Gökhan Taşkın')
content = content.replace('Bandrma Onyedi Eyll niversitesi', 'Bandırma Onyedi Eylül Üniversitesi')

# Remove from footer
author_pattern = re.compile(r'\s*<div class="author">.*?</div>', re.IGNORECASE)
advisor_pattern = re.compile(r'\s*<div class="advisor">.*?</div>', re.IGNORECASE)

content = author_pattern.sub('', content)
content = advisor_pattern.sub('', content)

# Insert into header below tagline
header_insert_html = '''
            <div class="team-info" style="margin-top: 25px; display: flex; flex-direction: column; align-items: center; gap: 10px;">
                <div class="author" style="font-size: 48px; margin-bottom: 0;">Geliştirici: Caner Tanik</div>
                <div class="advisor" style="font-size: 36px; margin-bottom: 0;">Danışman: Süleyman Gökhan Taşkın</div>
            </div>'''

tagline_pattern = re.compile(r'(<div class="tagline">.*?</div>)', re.IGNORECASE | re.DOTALL)
content = tagline_pattern.sub(r'\1' + header_insert_html, content)

with io.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
