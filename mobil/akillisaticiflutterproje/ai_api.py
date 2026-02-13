import json
import os
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

class AiRequest(BaseModel):
    title: str
    brand: Optional[str] = None
    size: Optional[str] = None
    pack: Optional[str] = None
    imageBase64: Optional[str] = None
    category: Optional[str] = None

class AiResponse(BaseModel):
    description: str
    priceRange: str
    category: str

@app.post("/ai/suggest", response_model=AiResponse)
def suggest(req: AiRequest):
    if not os.getenv("OPENAI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY tanımlı değil")

    system_prompt = (
        "Sen bir e-ticaret odaklı yapay zekasın. "
        "Görevin, verilen ürün fotoğrafını analiz ederek satıcıya yardımcı olacak bilgiler üretmektir. "
        "Görseli mutlaka kullan ve başlığa körü körüne güvenme. "
        "Çıktı formatı sadece JSON olmalı."
    )

    user_prompt = (
        "ADIM ADIM ŞUNLARI YAP:\n"
        "1) Ürün Fotoğrafı Analizi: Ürünü tespit et, tür ve kullanım amacını belirle, görünen özellikleri çıkar.\n"
        "2) Ürün Başlığı: Türkçe, SEO uyumlu, profesyonel. Marka bilinmiyorsa uydurma.\n"
        "3) Ürün Açıklaması: Uzun (6-8 cümle) ve en az 500 karakter; satış odaklı; kesin iddialardan kaçın.Ürün herhangi bir besin ise besin değerlerini de ekle ve hayvansan besin ise kaç yaş hayvanların yiyebileceğini belirt.Eğer bu ürün kullanılacak bir ürünse ürünün özelliklerini detaylandır.\n"
        "4) Kategori: Türkiye e-ticaret kategorisi seç.\n"
        "5) Fiyat Önerisi: Canlı web sitelerine bağlanma, scraping yapma, kesin fiyat verme.\n"
        "   Tahmini fiyat aralığı üret ve bunun tahmini olduğunu belirt.\n"
        "6) Güven Skoru: 0.0–1.0 arası güven skoru.\n\n"
        "Sadece aşağıdaki JSON'u döndür (başka metin ekleme):\n"
        "{\n"
        "  \"title\": \"string\",\n"
        "  \"category\": \"string\",\n"
        "  \"description\": \"string\",\n"
        "  \"suggested_price_min\": number,\n"
        "  \"suggested_price_max\": number,\n"
        "  \"confidence\": number\n"
        "}\n\n"
        f"Ürün başlığı (kullanıcı): {req.title}\n"
        f"Kategori (kullanıcı): {req.category or ''}\n"
        f"Marka (kullanıcı): {req.brand or ''}\n"
        f"Boyut/Gramaj (kullanıcı): {req.size or ''}\n"
        f"Paket Adedi (kullanıcı): {req.pack or ''}\n"
        "Not: Ürün görseli ile çelişen başlığı düzelt."
    )

    content = [{"type": "text", "text": user_prompt}]
    if req.imageBase64:
        content.append(
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:image/jpeg;base64,{req.imageBase64}",
                },
            }
        )

    resp = _client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": content},
        ],
        temperature=0.4,
        max_tokens=900,
        response_format={"type": "json_object"},
    )

    raw = resp.choices[0].message.content or "{}"
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Model JSON döndürmedi")

    title = str(data.get("title", req.title)).strip()
    desc = str(data.get("description", "")).strip()
    category = str(data.get("category", req.category or "Ev & Yaşam")).strip()
    price_min = data.get("suggested_price_min")
    price_max = data.get("suggested_price_max")
    if isinstance(price_min, (int, float)) and isinstance(price_max, (int, float)):
        price_range = f"₺{int(price_min)} - ₺{int(price_max)} (tahmini)"
    else:
        price_range = "₺200 - ₺500 (tahmini)"

    if not desc:
        desc = f"{title} ürünü, günlük kullanım için uygundur."

    if len(desc) < 500:
        desc = (
            desc
            + f" Bu ürün, {category} kategorisinde pratik kullanım ve güvenilir performans odaklı bir seçenektir. "
            + "Günlük kullanım senaryolarında kolay adaptasyon sağlar ve kullanıcı deneyimini iyileştirmeyi hedefler. "
            + "Dengeli formül/özellik yapısı sayesinde düzenli kullanımda istikrarlı sonuçlar hedeflenir. "
            + "Saklama ve kullanım önerilerine uyulduğunda ürün performansının korunması amaçlanır."
        )

    return AiResponse(description=desc, priceRange=price_range, category=category)
