import json
import logging
import os
import re
import time
import base64
from collections import Counter
from statistics import median, mean, stdev
from typing import Optional
from urllib.parse import quote_plus
from urllib.request import Request as UrlRequest, urlopen

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI

app = FastAPI()
logger = logging.getLogger("ai_api")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _get_openai_client() -> Optional[OpenAI]:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None
    return OpenAI(api_key=api_key)


def _guess_pet_type_from_text(text: str) -> str:
    t = (text or "").lower()
    if any(x in t for x in ["kedi", "kitten", "cat"]):
        return "kedi"
    if any(x in t for x in ["kopek", "köpek", "dog", "puppy"]):
        return "köpek"
    if any(x in t for x in ["kus", "kuş", "bird"]):
        return "kuş"
    if any(x in t for x in ["balik", "balık", "fish"]):
        return "balık"
    return "genel"


def _normalize_brand_name(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    text = re.sub(r"\s+", " ", str(value)).strip()
    return text or None


def _infer_brand_from_text(*texts: Optional[str]) -> Optional[str]:
    haystack = " ".join(text for text in texts if text).lower()
    if not haystack:
        return None

    brand_patterns = [
        ("purina pro plan", "Purina Pro Plan"),
        ("royal canin", "Royal Canin"),
        ("hill's", "Hill's"),
        ("hills", "Hill's"),
        ("pro plan", "Purina Pro Plan"),
        ("acana", "Acana"),
        ("orijen", "Orijen"),
        ("farmina", "Farmina"),
        ("brit care", "Brit Care"),
        ("brit", "Brit"),
        ("whiskas", "Whiskas"),
        ("felix", "Felix"),
        ("friskies", "Friskies"),
        ("pedigree", "Pedigree"),
        ("bonnie", "Bonnie"),
        ("reflex", "Reflex"),
        ("advance", "Advance"),
        ("gourmet", "Gourmet"),
        ("matisse", "Matisse"),
        ("n&d", "N&D"),
        ("nd", "N&D"),
    ]

    for needle, normalized in brand_patterns:
        if needle in haystack:
            return normalized

    return None


def _is_query_too_generic(query: str) -> bool:
    """Return True if query is too generic (e.g., 'mama 10kg', 'kedi maması 500g')
    by removing size tokens and common generic words and checking remaining meaningful tokens.
    """
    if not query:
        return True
    q = query.lower()
    # remove numeric size tokens like '10kg', '500g', '1 adet', '1l'
    q_no_size = re.sub(r"\b\d+(?:[\.,]\d+)?\s*(kg|g|gr|gram|adet|l|lt|litre)?\b", "", q)
    tokens = re.findall(r"[a-zA-ZÇĞİÖŞÜçğıöşü]+", q_no_size)
    generic = {
        "mama",
        "mamasi",
        "maması",
        "kedi",
        "köpek",
        "pet",
        "ürün",
        "gıda",
        "kedi",
        "köpek",
    }
    meaningful = [t for t in tokens if t not in generic]
    return len(meaningful) == 0


def _extract_brand_candidate_from_title(title: Optional[str]) -> Optional[str]:
    """Basit bir heuristik: başlıkta 'mama' veya 'maması' gibi kelimeden önce gelen token'ı marka adayı olarak al.
    Ayrıca başlığın ilk kelimesi büyük harfle başlıyorsa (ve genel bir kelime değilse) onu marka adayı olarak döndürür.
    """
    if not title:
        return None
    t = title.strip()
    low = t.lower()

    # Öne çıkan token öncesi marka adayı (ör: "Bonnie Dana Köpek Maması 10kg")
    m = re.search(r"([\wÇĞİÖŞÜçğıöşü]+)\s+(?:mama|mamasi|maması|maması|köpek maması|kedi maması|kedi|köpek)\b", low)
    if m:
        candidate = m.group(1)
        # normalize & capitalize
        cand = candidate.strip()
        if cand:
            return cand.capitalize()

    # Eğer başlıkın ilk kelimesi uygun görünüyorsa (kısa ve alfa karakterler içeriyorsa)
    first = t.split()[0]
    if re.match(r"^[A-Za-zÇĞİÖŞÜçğıöşü0-9\-\.]+$", first) and len(first) <= 20:
        # Ignore generic tokens
        generic = {"mama", "kedi", "köpek", "pet", "ürün", "paket", "gıda"}
        if first.lower() not in generic:
            return first.strip().capitalize()

    return None


def _offline_ai_suggest(req: "AiRequest") -> "AiResponse":
    min_est, max_est = _heuristic_price_range(f"{req.brand or ''} {req.title or ''} {req.size or ''} {req.category or ''}".strip() or "pet ürünü")
    price_range = f"₺{int(min_est)} - ₺{int(max_est)} (tahmini)"
    category = (req.category or "Pet Shop").strip() or "Pet Shop"
    pet_type = _guess_pet_type_from_text(f"{req.title} {req.category or ''} {req.pack or ''}")
    brand = _normalize_brand_name(req.brand) or _infer_brand_from_text(req.title, req.category, req.size, req.pack)
    title_bits = [brand or None, category if category.lower() not in {"pet shop", "ev & yaşam"} else None, req.size]
    title = " ".join(bit for bit in title_bits if bit).strip() or (req.title or "Ürün")

    description = (
        f"{title}, {category} kategorisinde {pet_type} için uygun bir seçenek olarak önerilir. "
        "Ürün görseli analiz edilirken servis çevrimdışı modda çalıştığı için detaylar başlık ve kategori bilgisine göre tahmini olarak oluşturulmuştur. "
        "Satış metnini yayına almadan önce ürün ambalajı üzerindeki içerik, kullanım talimatı ve gramaj bilgilerini doğrulamanız önerilir. "
        "Fiyat aralığı güncel piyasa koşullarına göre yaklaşık değer olarak üretilmiştir ve kampanya dönemlerinde değişebilir. "
        "Daha doğru AI çıktısı için OPENAI_API_KEY tanımlandığında görselden zengin analiz otomatik olarak devreye girer."
    )

    return AiResponse(
        title=title,
        description=description,
        priceRange=price_range,
        category=category,
        petType=pet_type,
        brand=brand,
        weight=req.size,
    )

class AiRequest(BaseModel):
    title: str
    brand: Optional[str] = None
    size: Optional[str] = None
    pack: Optional[str] = None
    imageUrl: Optional[str] = None
    imageBase64: Optional[str] = None
    imageMimeType: Optional[str] = None
    category: Optional[str] = None

class AiResponse(BaseModel):
    title: str
    description: str
    priceRange: str
    category: str
    petType: str
    brand: Optional[str] = None
    weight: Optional[str] = None  # Örn: "10kg", "500g", null
    minPrice: Optional[float] = None
    maxPrice: Optional[float] = None


class PriceScrapeRequest(BaseModel):
    query: str
    brand: Optional[str] = None
    urls: Optional[list[str]] = None
    maxPages: int = 3
    weight: Optional[str] = None  # Ürün gramajı (ör: "10kg", "500g")


class PriceScrapeResponse(BaseModel):
    # Geriye dönecek zenginleştirilmiş fiyat bilgileri
    query: str
    brand: Optional[str] = None
    minPrice: Optional[float]
    maxPrice: Optional[float]
    medianPrice: Optional[float]
    modePrice: Optional[float]
    # Yeni alanlar
    suggestedPrice: Optional[float]
    quickSalePrice: Optional[float]
    premiumPrice: Optional[float]
    sampleCount: int
    scannedUrls: list[str]
    confidence: float
    note: str

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    systemContext: Optional[str] = None

class ChatResponse(BaseModel):
    reply: str


def _normalize_mime(value: Optional[str]) -> str:
    raw = (value or "").strip().lower()
    if raw in {"image/jpg", "image/pjpeg", "jpg", "jpeg"}:
        return "image/jpeg"
    if raw in {"image/png", "png"}:
        return "image/png"
    if raw in {"image/gif", "gif"}:
        return "image/gif"
    if raw in {"image/webp", "webp"}:
        return "image/webp"
    return ""


def _guess_mime_from_bytes(blob: bytes) -> str:
    if len(blob) >= 3 and blob[:3] == b"\xFF\xD8\xFF":
        return "image/jpeg"
    if len(blob) >= 8 and blob[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if len(blob) >= 6 and blob[:6] in (b"GIF87a", b"GIF89a"):
        return "image/gif"
    if len(blob) >= 12 and blob[:4] == b"RIFF" and blob[8:12] == b"WEBP":
        return "image/webp"
    return ""


def _build_data_url_from_base64(image_base64: str, image_mime: Optional[str]) -> str:
    try:
        blob = base64.b64decode(image_base64, validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail="imageBase64 geçersiz")

    guessed = _guess_mime_from_bytes(blob)
    normalized = _normalize_mime(image_mime)
    mime = guessed or normalized
    if not mime:
        raise HTTPException(
            status_code=400,
            detail="Desteklenmeyen görsel formatı. Sadece png/jpeg/gif/webp kabul edilir.",
        )

    encoded = base64.b64encode(blob).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def _build_data_url_from_remote(image_url: str) -> str:
    try:
        req = UrlRequest(
            image_url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "ngrok-skip-browser-warning": "1",
            },
        )
        with urlopen(req, timeout=20) as resp:
            blob = resp.read()
            content_type = resp.headers.get("Content-Type", "")
    except Exception:
        import traceback
        tb = traceback.format_exc()
        logger.exception("imageUrl indirilemedi: %s", image_url)
        # include short exception message in response for debugging (not stacktrace)
        raise HTTPException(status_code=400, detail=f"imageUrl indirilemedi: {str(tb).splitlines()[-1]}")

    guessed = _guess_mime_from_bytes(blob)
    normalized = _normalize_mime(content_type)
    mime = guessed or normalized
    if not mime:
        raise HTTPException(
            status_code=400,
            detail="imageUrl desteklenmeyen format döndürdü. png/jpeg/gif/webp gerekli.",
        )

    encoded = base64.b64encode(blob).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def _default_search_urls(query: str) -> list[str]:
    q = quote_plus(query)
    return [
        f"https://www.trendyol.com/sr?q={q}",
        f"https://www.hepsiburada.com/ara?q={q}",
        f"https://www.n11.com/arama?q={q}",
    ]


def _scrape_serpapi_shopping(query: str) -> tuple[list[float], list[str]]:
    """SerpAPI ile Google Shopping'den gerçek fiyat çeker. SERPAPI_KEY gerekli."""
    api_key = os.getenv("SERPAPI_KEY", "").strip()
    if not api_key:
        return [], []

    try:
        q = quote_plus(query)
        url = (
            f"https://serpapi.com/search.json"
            f"?engine=google_shopping&q={q}&gl=tr&hl=tr&currency=TRY&api_key={api_key}"
        )
        req = UrlRequest(url, headers={"User-Agent": "Mozilla/5.0"})
        with urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception as ex:
        logger.warning("SerpAPI isteği başarısız: %s", ex)
        return [], [f"https://serpapi.com (hata: {ex})"]

    results = data.get("shopping_results", [])
    prices: list[float] = []
    for item in results:
        price_raw = item.get("price") or item.get("extracted_price")
        if price_raw is None:
            continue
        if isinstance(price_raw, (int, float)):
            val = float(price_raw)
        else:
            # "₺129,00" veya "129.00" formatlarını çöz
            cleaned = re.sub(r"[₺TL\s]", "", str(price_raw)).replace(".", "").replace(",", ".")
            try:
                val = float(cleaned)
            except ValueError:
                continue
        if 5 <= val <= 200_000:
            prices.append(val)

    scanned = [f"https://serpapi.com/search (Google Shopping TR, {len(prices)} sonuç)"]
    prices = _filter_price_outliers(prices)
    logger.info("SerpAPI: %d fiyat çekildi", len(prices))
    return prices, scanned


def _scrape_google_shopping(query: str) -> tuple[list[float], list[str]]:
    """Google Shopping'den Selenium ile fiyat çeker (Türkiye)."""
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
    except ImportError:
        return [], []

    q = quote_plus(query)
    # İmkan varsa ilk 20-30 sonucu iste
    url = f"https://www.google.com.tr/search?tbm=shop&q={q}&gl=tr&hl=tr&num=30"

    options = Options()
    # headless=new yerine eski headless - bazı sistemlerde daha az tespit edilir
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1366,768")
    options.add_argument(
        "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    )
    options.add_argument("--lang=tr-TR,tr;q=0.9")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_experimental_option("excludeSwitches", ["enable-automation"])
    options.add_experimental_option("useAutomationExtension", False)

    prices: list[float] = []
    scanned: list[str] = []

    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(30)
    try:
        # CDP ile navigator.webdriver flag'ini gizle
        driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {
            "source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
        })

        driver.get(url)

        # Cookie / rıza popup'ını kapat
        try:
            btn = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((By.XPATH,
                    "//button[contains(., 'Kabul') or contains(., 'Accept') "
                    "or contains(., 'Agree') or contains(., 'Tümünü kabul')]"
                ))
            )
            btn.click()
            time.sleep(0.8)
        except Exception:
            pass

        time.sleep(2.5)

        # Sayfayı aşağı kaydır - lazy load tetikle
        driver.execute_script("window.scrollTo(0, 600);")
        time.sleep(1)

        # Google Shopping fiyat selector'ları (2024-2026 DOM)
        price_selectors = [
            "span.HRLxBb",
            "span.a8Pemb",
            "span.OFFNJ",
            "span[aria-label*='₺']",           # En güvenilir yol
            "span[aria-label*='TL']",
            ".sh-dgr__grid-result span[aria-label*='₺']",
            ".T14wmb",
            ".sh-np__click-target .a8Pemb",
            "[data-price]",
        ]

        seen_prices: set[float] = set()
        for selector in price_selectors:
            try:
                elements = driver.find_elements(By.CSS_SELECTOR, selector)
                for el in elements:
                    text = (el.text or "").strip()
                    if not text:
                        text = el.get_attribute("aria-label") or el.get_attribute("data-price") or ""
                    # Sadece ₺ ile başlayan değerleri kabul et (kirli metin engellemek için)
                    clean = text.strip()
                    if clean.startswith("₺") or re.match(r"^\d", clean):
                        v = _extract_price_from_single_value(clean)
                        if v is not None and v not in seen_prices:
                            seen_prices.add(v)
                            prices.append(v)
                            # Eğer yeterli sayıda fiyat toplandıysa erken çık
                            if len(prices) >= 30:
                                break
                if len(prices) >= 30:
                    break
            except Exception:
                continue

        # Son çare: sayfa kaynağını regex ile tara
        if not prices:
            page_text = driver.page_source
            prices = _extract_prices_from_text(page_text)

        scanned.append(url)
        logger.info("Google Shopping: %d ham fiyat çıkarıldı", len(prices))
    except Exception as e:
        logger.warning("Google Shopping scrape hatası: %s", e)
        scanned.append(url)
    finally:
        try:
            driver.quit()
        except Exception:
            pass

    prices = _filter_price_outliers(prices)
    return prices, scanned


def _parse_weight_to_kg(weight: Optional[str]) -> Optional[float]:
    """Örn: '500g' -> 0.5, '1kg' -> 1.0, '250 gr' -> 0.25. None veya çözülemezse None döner."""
    if not weight:
        return None
    w = str(weight).strip().lower()
    # normalize 'g', 'gr', 'kg', 'kilogram'
    m = re.search(r"(\d+(?:[\.,]\d+)?)\s*(kg|kilo|kilogram|g|gr|gram)\b", w)
    if not m:
        return None
    val = float(m.group(1).replace(",", "."))
    unit = m.group(2)
    if unit.startswith("g"):
        return round(val / 1000.0, 6)
    return round(val, 6)


def _extract_prices_from_text(text: str) -> list[float]:
    matches = re.findall(
        r"(?:₺|TL)\s*(\d{1,3}(?:[\.\s]\d{3})*(?:,\d{2})|\d+(?:,\d{2})?)",
        text,
    )
    values: list[float] = []

    for item in matches:
        normalized = item.replace(" ", "").replace(".", "").replace(",", ".")
        try:
            value = float(normalized)
            if 5 <= value <= 200000:
                values.append(value)
        except ValueError:
            continue

    return values


def _extract_price_from_single_value(text: str) -> Optional[float]:
    text = text.strip()
    if not text:
        return None

    lower_text = text.lower()
    blocked_tokens = [
        "değerlendirme",
        "yorum",
        "satıcı",
        "takipçi",
        "taksit",
        "puan",
        "indirim",
        "favori",
    ]
    if any(token in lower_text for token in blocked_tokens):
        return None

    has_currency = ("₺" in text) or ("TL" in text.upper())

    match = re.search(r"(\d{1,3}(?:[\.\s]\d{3})*(?:,\d{2})|\d+(?:,\d{2})?)", text)
    if not match:
        return None

    normalized = match.group(1).replace(" ", "").replace(".", "").replace(",", ".")
    try:
        value = float(normalized)
        if not has_currency and not (50 <= value <= 50000):
            return None
        if 5 <= value <= 200000:
            return value
    except ValueError:
        return None
    return None


def _selector_map(url: str) -> list[str]:
    if "trendyol.com" in url:
        return [
            ".prc-box-dscntd",
            ".prc-box-sllng",
            ".price-item",
            "span[class*='price']",
        ]
    if "hepsiburada.com" in url:
        return [
            "[data-test-id='price-current-price']",
            ".price-value",
            "div[class*='price'] span",
        ]
    if "n11.com" in url:
        return [
            ".price-current",
            ".newPrice ins",
            "span[class*='price']",
        ]
    return ["span[class*='price']", "div[class*='price']"]


def _filter_price_outliers(prices: list[float]) -> list[float]:
    if not prices:
        return []

    sorted_prices = sorted(prices)
    if len(sorted_prices) < 6:
        return sorted_prices

    q1 = sorted_prices[len(sorted_prices) // 4]
    q3 = sorted_prices[(len(sorted_prices) * 3) // 4]
    iqr = q3 - q1
    low = max(5, q1 - 1.5 * iqr)
    high = q3 + 1.5 * iqr

    filtered = [p for p in sorted_prices if low <= p <= high]
    return filtered if filtered else sorted_prices


def _calculate_mode_price(prices: list[float]) -> Optional[float]:
    if not prices:
        return None

    bucketed_prices = [int(round(price / 50.0) * 50) for price in prices]
    frequencies = Counter(bucketed_prices)
    mode_bucket, mode_count = frequencies.most_common(1)[0]

    if mode_count <= 1:
        return round(median(prices), 2)

    bucket_values = [price for price in prices if int(round(price / 50.0) * 50) == mode_bucket]
    if not bucket_values:
        return float(mode_bucket)

    return round(median(bucket_values), 2)


def _heuristic_price_range(query: str) -> tuple[float, float]:
    q = query.lower()

    # ── Aksesuar / Oyuncak kategorileri (kg bağımsız, küçük ürünler) ─────────
    # Kedi/köpek küçük oyuncak (top, fare, tüy, zilli, çıngıraklı vb.)
    small_toy_kws = ["zilli", "çıngıraklı", "tüylü", "fare", "peluş top", "lazer",
                     "jingle", "feather", "catnip"]
    if any(kw in q for kw in small_toy_kws):
        return (40.0, 180.0)

    if "oyuncak" in q:
        # Büyük oyuncak seti / tırmalama / kedi evi ayrımı
        if any(kw in q for kw in ["tırmalama", "kedi evi", "kedi kulesi", "kedi tahtası"]):
            return (200.0, 900.0)
        # Genel küçük/orta oyuncak
        return (50.0, 250.0)

    if "yatak" in q or "sepet" in q or "köpek yatağı" in q or "kedi yatağı" in q:
        return (200.0, 1000.0)

    if "kedi evi" in q or "kedi kulesi" in q or "tırmalama" in q:
        return (200.0, 900.0)

    if "tasma" in q or "koşum" in q or "gezdirme" in q:
        return (100.0, 600.0)

    if "kafes" in q or "taşıma çantası" in q or "taşıma" in q:
        return (300.0, 1800.0)

    if "ödül" in q or "treat" in q or "snack" in q:
        return (80.0, 400.0)

    if "kum" in q or "tuvalet" in q:
        return (150.0, 700.0)

    if "şampuan" in q or "tarak" in q or "fırça" in q or "bakım" in q:
        return (80.0, 400.0)

    # ── Mama / gıda ürünleri (kg'a göre hesapla) ────────────────────────────
    # 2026 Türkiye petshop fiyat tabanı (kg yoksa genel mama varsayımı)
    min_price = 250.0
    max_price = 900.0

    kg_match = re.search(r"(\d+(?:[\.,]\d+)?)\s*kg", q)
    if kg_match:
        kg = float(kg_match.group(1).replace(",", "."))
        unit_min = 150.0   # TL/kg alt bant
        unit_max = 380.0   # TL/kg üst bant

        # Ekonomik markalar
        if any(brand in q for brand in ["bonnie", "whiskas", "felix", "friskies", "pedigree", "catlife"]):
            unit_min = 60.0
            unit_max = 150.0

        min_price = kg * unit_min
        max_price = kg * unit_max

    # Premium marka çarpanları
    if any(brand in q for brand in ["royal canin", "orijen", "acana"]):
        min_price *= 1.5
        max_price *= 1.7
    elif any(brand in q for brand in ["pro plan", "hill", "hills", "purina"]):
        min_price *= 1.3
        max_price *= 1.5
    elif any(brand in q for brand in ["brit", "farmina", "taste of the wild"]):
        min_price *= 1.1
        max_price *= 1.3

    return (round(min_price, 2), round(max_price, 2))


def _scrape_prices_with_selenium(urls: list[str], max_pages: int) -> tuple[list[float], list[str]]:
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="Selenium yüklü değil. Kurulum: pip install selenium",
        )

    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")

    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(25)

    all_prices: list[float] = []
    scanned: list[str] = []

    try:
        for url in urls[:max_pages]:
            try:
                driver.get(url)
                time.sleep(2.5)

                collected: list[float] = []

                if "trendyol.com" in url:
                    cards = driver.find_elements(
                        By.CSS_SELECTOR,
                        ".p-card-wrppr, .p-card-wrppr-with-campaign-view",
                    )
                    card_price_selectors = [
                        ".prc-box-dscntd",
                        ".prc-box-sllng",
                        "span[class*='price']",
                    ]
                    for card in cards:
                        for selector in card_price_selectors:
                            elements = card.find_elements(By.CSS_SELECTOR, selector)
                            for element in elements:
                                value = _extract_price_from_single_value(element.text)
                                if value is not None:
                                    collected.append(value)
                else:
                    selectors = _selector_map(url)
                    for selector in selectors:
                        elements = driver.find_elements(By.CSS_SELECTOR, selector)
                        for element in elements:
                            value = _extract_price_from_single_value(element.text)
                            if value is not None:
                                collected.append(value)

                if not collected:
                    text = driver.page_source
                    collected = _extract_prices_from_text(text)

                all_prices.extend(collected)
                scanned.append(url)
            except Exception:
                scanned.append(url)
                continue
    finally:
        driver.quit()

    prices = _filter_price_outliers(all_prices)
    return prices, scanned

@app.post("/ai/suggest", response_model=AiResponse)
async def suggest(request: Request):
    # Log raw incoming body for debugging (trim large payloads)
    try:
        body = await request.json()
    except Exception:
        body = None
    info_text = f"/ai/suggest called from {request.client.host if request.client else '-'} body={(json.dumps(body)[:2000] if body is not None else '<no-json>')}"
    logger.info(info_text)
    # Also print to stdout so uvicorn terminal capture shows it immediately
    print(info_text)

    # Validate and coerce into AiRequest
    try:
        req = AiRequest(**(body or {}))
    except Exception as ex:
        raise HTTPException(status_code=422, detail=str(ex))

    client = _get_openai_client()
    if not req.imageBase64 and not req.imageUrl:
        raise HTTPException(status_code=400, detail="Görsel zorunlu: imageBase64 veya imageUrl boş")

    if client is None:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY tanımlı değil; görsel analiz için vision modu zorunlu")

    system_prompt = (
        "Sen bir petshop e-ticaret odaklı yapay zekasın. "
        "Görevin, verilen ürün fotoğrafını analiz ederek satıcıya yardımcı olacak bilgiler üretmektir. "
        "Görseli esas al; kullanıcıdan gelen başlık bilgisi varsa bile ona güvenme. "
        "Ürün fotoğrafından hareketle başlık, marka, kategori, gramaj ve açıklama üret. "
        "Çıktı formatı sadece JSON olmalı."
    )

    user_prompt = (
        "ADIM ADIM ŞUNLARI YAP:\n"
        "1) Ürün Fotoğrafı Analizi: Ürünü tespit et, pakette görünen yazıları oku, seri/çeşit/özellik bilgilerini çıkar.\n"
        "2) Ürün Başlığı: Türkçe, SEO uyumlu, profesyonel ve görselden türetilmiş olmalı. Genel cevap verme. 'mama', 'kedi maması' gibi kısa başlıklar yazma. Başlık; marka + seri + ürün tipi + aroma/özellik bilgilerini içersin. Marka görünmüyorsa marka uydurma.\n"
        "3) Ürün Açıklaması: Uzun (6-8 cümle) ve en az 500 karakter; satış odaklı; kesin iddialardan kaçın. "
        "Ürün herhangi bir besin ise besin değerlerini de ekle ve hayvan besini ise kaç yaş hayvanların yiyebileceğini belirt. "
        "Eğer bu ürün kullanılacak bir ürünse ürünün özelliklerini detaylandır.\n"
        "4) Kategori: Türkiye e-ticaret kategorisi seç.\n"
        "4.5) Marka: Ürünün üzerindeki marka veya logo bilgisini tespit et (yoksa null).\n"
        "4.6) Gramaj/Ağırlık: Ürün fotoğrafından görseldeki paket/boyut bilgisini çıkar (kg, g vb.). Örn: \"10kg\", \"500g\", \"1 litre\". Yoksa null.\n"
        "5) Fiyat Önerisi (ÇOK ÖNEMLİ - 2026 Türkiye piyasası):\n"
        "   Görseldeki ürünü dikkatle incele: marka logosu, gramaj/kg bilgisi, ürün tipi.\n"
        "   2026 yılı Türkiye petshop e-ticaret fiyatlarını baz al (enflasyon göz önünde bulundurulmuş).\n"
        "   Referans fiyat rehberi (2026 TL):\n"
        "   - Premium mama (Royal Canin, Purina Pro Plan, Hill's, Orijen, Acana):\n"
        "       1 kg: 350-600 TL | 3 kg: 900-1800 TL | 10 kg: 2500-5000 TL | 15 kg: 3500-7000 TL\n"
        "   - Orta segment mama (Whiskas, Felix, Pedigree, Friskies, Brit):\n"
        "       1 kg: 150-300 TL | 3 kg: 400-800 TL | 10 kg: 1200-2500 TL\n"
        "   - Ekonomik mama (Catlife, Bonnie, yerel marka):\n"
        "       1 kg: 60-150 TL | 3 kg: 150-400 TL | 10 kg: 500-1200 TL\n"
        "   - Kedi/köpek KÜÇÜK oyuncak (top, fare, tüy, zilli, çıngıraklı set):\n"
        "       Tekli: 40-100 TL | 2-4 adetlik paket: 50-150 TL | Büyük set: 100-250 TL\n"
        "   - Tırmalama tahtası/postu (orta boy): 150-500 TL | Kedi kulesi/evi: 400-2000 TL\n"
        "   - Kedi/köpek yatağı/sepeti: 200-1000 TL\n"
        "   - Tasma/koşum (orta): 100-600 TL | Kafes (orta): 400-2000 TL\n"
        "   - Taşıma çantası/kutusu: 300-1500 TL\n"
        "   - Kedi kumu (10 L): 100-350 TL | Bentonit kum 25 kg: 300-700 TL\n"
        "   - Ödül/snack: 80-400 TL | Bakım ürünleri (şampuan, tarak): 80-400 TL\n"
        "   Görselden ürünü ve markayı tanımla, gramaj/boyutunu tahmin et ve yukarıdaki rehberi kullanarak\n"
        "   GERÇEKÇI bir fiyat aralığı üret. Örn: küçük oyuncak paketi için 150-500 gibi genel mama fiyatı KULLANMA.\n"
        "6) Güven Skoru: 0.0–1.0 arası güven skoru.\n\n"
        "Sadece aşağıdaki JSON'u döndür (başka metin ekleme):\n"
        "{\n"
        "  \"title\": \"string\",\n"
        "  \"category\": \"string\",\n"
        "  \"pet_type\": \"string (örn: kedi, köpek, kuş, balık veya genel)\",\n"
        "  \"description\": \"string\",\n"
        "  \"brand\": \"string veya null\",\n"
        "  \"weight\": \"string veya null (örn: 10kg, 500g, 1 litre)\",\n"
        "  \"suggested_price_min\": number,\n"
        "  \"suggested_price_max\": number,\n"
        "  \"confidence\": number\n"
        "}\n\n"
        f"Ürün başlığı (kullanıcı notu, varsa): {req.title or ''}\n"
        f"Kategori (kullanıcı): {req.category or ''}\n"
        f"Marka (kullanıcı): {req.brand or ''}\n"
        f"Boyut/Gramaj (kullanıcı): {req.size or ''}\n"
        f"Paket Adedi (kullanıcı): {req.pack or ''}\n"
        "Not: Ürün görseli ile çelişen başlığı düzelt. Kullanıcı notunu yalnızca yardımcı sinyal olarak değerlendir. Başlık genel olmasın; ürünün pakette görünen adı, seri adı ve ayırt edici özelliğini yansıtsın. Fiyatı ürünün gerçek piyasa değerine göre belirle."
    )

    image_data_url = ""
    if req.imageBase64:
        try:
            image_data_url = _build_data_url_from_base64(req.imageBase64, req.imageMimeType)
        except HTTPException:
            if req.imageUrl:
                image_data_url = _build_data_url_from_remote(req.imageUrl.strip())
            else:
                raise
    elif req.imageUrl:
        image_data_url = _build_data_url_from_remote(req.imageUrl.strip())

    def _call_openai(data_url: str):
        content = [
            {"type": "text", "text": user_prompt},
            {
                "type": "image_url",
                "image_url": {
                    "url": data_url,
                },
            },
        ]

        return client.chat.completions.create(
            model="gpt-4.1-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": content},
            ],
            temperature=0.4,
            max_tokens=900,
            response_format={"type": "json_object"},
        )

    try:
        resp = _call_openai(image_data_url)
    except Exception as ex:
        error_text = str(ex)
        # If a remote URL exists and parsing failed for the base64, try using remote
        if req.imageUrl and req.imageBase64 and "image_parse_error" in error_text:
            try:
                fallback_data_url = _build_data_url_from_remote(req.imageUrl.strip())
                resp = _call_openai(fallback_data_url)
            except Exception as fallback_ex:
                raise HTTPException(status_code=400, detail=f"OpenAI görsel işleyemedi: {str(fallback_ex)}")
        else:
            raise HTTPException(status_code=400, detail=f"OpenAI görsel işleyemedi: {error_text}")

    content_str = resp.choices[0].message.content
    try:
        data = json.loads(content_str)
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="OpenAI geçersiz JSON döndürdü")

    title = str(data.get("title") or "").strip()
    desc = str(data.get("description", "")).strip()
    brand = data.get("brand")
    if isinstance(brand, str):
        brand = brand.strip() or None
    else:
        brand = None
    # İlk olarak modelin döndürdüğü markayı kullan, yoksa metin üzerinden çıkarmayı dene.
    brand = brand or _infer_brand_from_text(title, desc, req.title, req.category, req.size, req.pack)
    # Eğer hala yoksa başlıktan basit bir marka adayı çıkar
    if not brand:
        candidate = _extract_brand_candidate_from_title(title)
        if candidate:
            brand = candidate
    brand_hint = f"{title} {desc} {req.title or ''} {req.category or ''} {req.size or ''} {req.pack or ''}".lower()
    if brand == "Purina" and "pro plan" in brand_hint:
        brand = "Purina Pro Plan"
    category = str(data.get("category") or req.category or "Ev & Yaşam").strip()
    pet_type = str(data.get("pet_type", "")).strip()
    price_min = data.get("suggested_price_min")
    price_max = data.get("suggested_price_max")

    # Validate and clamp model prices against heuristic range to avoid unrealistic suggestions
    heuristic_min, heuristic_max = _heuristic_price_range(f"{req.brand or ''} {req.title or ''} {req.size or ''} {req.category or ''}")

    def _is_valid_price_pair(a, b):
        try:
            return isinstance(a, (int, float)) and isinstance(b, (int, float)) and a > 0 and b > a
        except Exception:
            return False

    if _is_valid_price_pair(price_min, price_max):
        # GPT'nin fiyatını sadece gerçekten saçma ise (10x sapma) reddet.
        # Eskiden 0.5x / 1.5x sınırı GPT'nin doğru fiyatlarını da eziyordu.
        min_floor = max(1, heuristic_min * 0.1)
        max_ceil = heuristic_max * 10.0
        if price_min < min_floor or price_max > max_ceil:
            price_min, price_max = heuristic_min, heuristic_max
        # else: GPT fiyatını koru
    else:
        price_min, price_max = heuristic_min, heuristic_max

    price_range = f"₺{int(price_min)} - ₺{int(price_max)} (tahmini)"

    if not title:
        title = (brand or "").strip()
        if category:
            title = f"{title} {category}".strip() if title else category
        if req.size:
            title = f"{title} {req.size}".strip() if title else req.size
        title = title or (req.title or "Ürün")

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

    weight = data.get("weight") or req.size
    if weight and isinstance(weight, str):
        weight = weight.strip() or None

    return AiResponse(title=title, description=desc, priceRange=price_range, category=category, petType=pet_type, brand=brand, weight=weight, minPrice=price_min, maxPrice=price_max)


def _parse_price_scrape_payload(raw_body: bytes) -> PriceScrapeRequest:
    try:
        payload = json.loads(raw_body.decode("utf-8"))
    except Exception:
        raise HTTPException(status_code=400, detail="Geçersiz JSON body")

    # Bazı proxy/client kombinasyonlarında gövde JSON string olarak gelebiliyor.
    if isinstance(payload, str):
        try:
            payload = json.loads(payload)
        except Exception:
            raise HTTPException(status_code=400, detail="price-scrape body geçersiz")

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="price-scrape body nesne olmalı")

    return PriceScrapeRequest(**payload)


@app.post("/price/scrape", response_model=PriceScrapeResponse)
async def scrape_price(request: Request):
    raw_body = await request.body()
    logger.info("price-scrape raw body: %s", raw_body.decode("utf-8", errors="replace"))
    req = _parse_price_scrape_payload(raw_body)
    query = req.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="query boş olamaz")

    # If client didn't provide brand and query is too generic (e.g. 'mama 10kg'),
    # block scraping to avoid pulling all generic results.
    if (not req.brand or str(req.brand).strip().lower() == 'null') and _is_query_too_generic(query):
        raise HTTPException(status_code=400, detail="Fiyat sorgusu çok genel. AI title/brand gereklidir.")

    brand = req.brand
    if (not brand or str(brand).strip().lower() == "null") and "bonnie" in query.lower():
        brand = "Bonnie"

    # Marka/gramaj bilgisi varsa sorguya ekle (örn: "Royal Canin" + "10kg")
    # Eğer istemci zaten query'ye marka eklemediyse burada ekliyoruz.
    if brand:
        brand_str = brand.strip()
        if brand_str and brand_str.lower() not in query.lower():
            query = f"{brand_str} {query}"

    if req.weight:
        weight_str = req.weight.strip()
        if weight_str and weight_str.lower() not in query.lower():
            query = f"{query} {weight_str}"

    max_pages = max(1, min(req.maxPages, 5))
    use_custom_urls = bool(req.urls and len(req.urls) > 0)

    prices: list[float] = []
    scanned: list[str] = []

    # 0) Önce SerpAPI dene (SERPAPI_KEY varsa — en güvenilir yöntem)
    if not use_custom_urls and os.getenv("SERPAPI_KEY", "").strip():
        try:
            s_prices, s_scanned = _scrape_serpapi_shopping(query)
            prices.extend(s_prices)
            scanned.extend(s_scanned)
            logger.info("SerpAPI: %d fiyat", len(s_prices))
        except Exception as ex:
            logger.warning("SerpAPI başarısız: %s", ex)

    # 1) SerpAPI'den yeterli veri gelmezse Google Shopping Selenium dene
    if not use_custom_urls and len(prices) < 3:
        try:
            g_prices, g_scanned = _scrape_google_shopping(query)
            prices.extend(g_prices)
            scanned.extend(g_scanned)
            logger.info("Google Shopping: %d fiyat bulundu", len(g_prices))
        except Exception as ex:
            logger.warning("Google Shopping scrape başarısız: %s", ex)

    # 2) Hala yeterli veri yoksa Trendyol/Hepsiburada/N11 dene
    target_urls = req.urls if use_custom_urls else _default_search_urls(query)
    if len(prices) < 3:
        try:
            s_prices, s_scanned = _scrape_prices_with_selenium(target_urls, max_pages)
            prices.extend(s_prices)
            scanned.extend(s_scanned)
        except Exception as ex:
            logger.exception("Selenium scrape hatası: %s", ex)
            scanned.extend(target_urls[:max_pages])

    prices = _filter_price_outliers(prices)

    weight_mode = bool(req.weight or re.search(r'\d+\s*kg', query.lower()))
    heuristic_min, heuristic_max = _heuristic_price_range(query) if weight_mode else (0.0, 0.0)

    # Gramaj bilgisi varsa heuristic taban fiyatı hesapla ve düşük varyantları elele
    # Örn: "10kg" premium mama → düşük gramaj fiyatlarının karışmasını azalt.
    if prices and weight_mode:
        price_floor = heuristic_min * 0.50
        price_ceil = heuristic_max * 2.00
        filtered_by_weight = [p for p in prices if price_floor <= p <= price_ceil]
        if len(filtered_by_weight) >= 2:
            prices = filtered_by_weight

    if not prices:
        min_est, max_est = _heuristic_price_range(query)
        median_est = round((min_est + max_est) / 2, 2)
        return PriceScrapeResponse(
            query=query,
            brand=brand,
            minPrice=min_est,
            maxPrice=max_est,
            medianPrice=median_est,
            modePrice=None,
            suggestedPrice=median_est,
            quickSalePrice=round(median_est * 0.95, 2),
            premiumPrice=round(median_est * 1.05, 2),
            sampleCount=0,
            scannedUrls=scanned,
            confidence=0.0,
            note="Canlı fiyat verisi bulunamadı; ürün adına göre tahmini aralık döndürüldü.",
        )

    sample_count = len(prices)
    mode_price = _calculate_mode_price(prices)

    # Eğer istenen gramaj belirtilmişse, fiyatları TL/kg bazına çevirip temizle, sonra tekrar istenen paket için geri çevir.
    request_kg = _parse_weight_to_kg(req.weight) if req.weight else None
    used_prices = prices
    normalized_note = ""

    if request_kg and request_kg > 0:
        try:
            per_kg = [round(p / request_kg, 6) for p in prices if p > 0]
            per_kg = _filter_price_outliers(per_kg)
            if per_kg:
                med_per_kg = median(per_kg)
                min_per_kg = min(per_kg)
                max_per_kg = max(per_kg)
                # geri çevir: istenen paket için fiyat
                med_price = round(med_per_kg * request_kg, 2)
                min_price = round(min_per_kg * request_kg, 2)
                max_price = round(max_per_kg * request_kg, 2)
                used_prices = [round(p * request_kg, 2) for p in per_kg]
                normalized_note = f"Fiyatlar {request_kg}kg bazında normalize edildi."
            else:
                # normalize edilemedi; fallback
                med_price = round(median(prices), 2)
                min_price = round(min(prices), 2)
                max_price = round(max(prices), 2)
        except Exception:
            med_price = round(median(prices), 2)
            min_price = round(min(prices), 2)
            max_price = round(max(prices), 2)
    else:
        med_price = round(median(prices), 2)
        min_price = round(min(prices), 2)
        max_price = round(max(prices), 2)

    # Hesaplanan temel öneriler
    suggested = round(med_price, 2)
    quick_sale = round(suggested * 0.95, 2)
    premium = round(suggested * 1.05, 2)

    # Confidence: örnek sayısına ve fiyat dağılımına göre kabaca hesapla
    try:
        variance_factor = 0.0
        if len(used_prices) > 1:
            avg = mean(used_prices)
            sd = stdev(used_prices)
            cv = sd / avg if avg > 0 else 1.0
            variance_factor = max(0.0, 1.0 - min(0.8, cv))
    except Exception:
        variance_factor = 0.5

    sample_factor = min(1.0, sample_count / 30.0)
    confidence = round(max(0.0, min(1.0, sample_factor * max(0.2, variance_factor))), 2)

    note_parts = ["Sonuçlar Selenium/Google Shopping'den çekilen fiyatların medyanına dayanır."]
    if normalized_note:
        note_parts.append(normalized_note)
    note_parts.append("Aykırı değerler IQR ile temizlendi.")

    return PriceScrapeResponse(
        query=query,
        brand=brand,
        minPrice=round(min_price, 2),
        maxPrice=round(max_price, 2),
        medianPrice=round(med_price, 2),
        modePrice=mode_price,
        suggestedPrice=suggested,
        quickSalePrice=quick_sale,
        premiumPrice=premium,
        sampleCount=sample_count,
        scannedUrls=scanned,
        confidence=confidence,
        note=" ".join(note_parts),
    )

@app.post("/ai/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    client = _get_openai_client()
    if client is None:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY tanımlı değil; sohbet botu çevrimdışı.")

    system_prompt = (
        "Sen 'Akıllı Satıcı' uygulamasının uzman veteriner ve e-ticaret satış asistanısın. "
        "Müşterilere samimi, profesyonel ve kısa (2-4 cümle) cevaplar vermelisin. "
        "Evcil hayvanlarla ilgili sağlık, beslenme, bakım tavsiyeleri verebilir ve uygun ürün tipleri önerebilirsin. "
    )
    
    if request.systemContext:
        system_prompt += f"\n\nMüşteri ve Evcil Hayvan Bilgileri:\n{request.systemContext}"
        
    messages = [{"role": "system", "content": system_prompt}]
    
    for msg in request.messages:
        messages.append({"role": msg.role, "content": msg.content})
        
    try:
        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.7,
            max_tokens=500,
        )
        reply_content = resp.choices[0].message.content
        return ChatResponse(reply=reply_content)
    except Exception as ex:
        logger.error(f"Chat error: {ex}")
        raise HTTPException(status_code=500, detail="Sohbet servisi geçici olarak ulaşılamıyor.")
