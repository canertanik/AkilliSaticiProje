using AkilliSatici.Api.Data;
using AkilliSatici.Api.Dtos;
using AkilliSatici.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // tüm ürün endpointleri JWT ister
public class ProductsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProductsController(AppDbContext db) => _db = db;

    // JWT içinden userId çek
    private int GetUserId()
    {
        // JwtService'de Sub claim'e user.Id koymuştun
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(sub) || !int.TryParse(sub, out var userId))
            throw new UnauthorizedAccessException("Token içinde user id yok.");

        return userId;
    }

    [HttpGet("public")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPublished([FromQuery] string? category = null)
    {
        var q = _db.Products.AsNoTracking().Where(p => p.Status == ProductStatus.Published);

        if (!string.IsNullOrWhiteSpace(category))
            q = q.Where(p => p.Category == category.Trim());

        var list = await q.OrderByDescending(p => p.CreatedAtUtc).ToListAsync();
        return Ok(list);
    }

    [HttpGet("public/{id:int}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPublicById(int id)
    {
        var product = await _db.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id && p.Status == ProductStatus.Published);

        if (product is null) return NotFound();
        return Ok(product);
    }

    [HttpGet("admin/all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllForAdmin()
    {
        var list = await _db.Products
            .AsNoTracking()
            .OrderByDescending(p => p.CreatedAtUtc)
            .ToListAsync();

        return Ok(list);
    }

    [HttpPost("admin/upload-image")]
    [Authorize(Roles = "Admin")]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10 MB
    public async Task<IActionResult> UploadImage(IFormFile? file)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new { message = "Dosya seçilmedi." });

        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowed.Contains(ext))
            return BadRequest(new { message = "Sadece jpg, jpeg, png, webp veya gif yükleyebilirsiniz." });

        var imagesDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images");
        Directory.CreateDirectory(imagesDir);

        var uniqueName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(imagesDir, uniqueName);

        await using var stream = System.IO.File.Create(filePath);
        await file.CopyToAsync(stream);

        var url = $"/images/{uniqueName}";
        return Ok(new { url });
    }

    [HttpPost("admin/smart")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateSmart([FromBody] SmartProductCreateDto dto)
    {
        var userId = GetUserId();

        var product = new Product
        {
            UserId = userId,
            Title = dto.Title.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.GeneratedDescription)
                ? BuildSmartDescription(dto)
                : dto.GeneratedDescription.Trim(),
            MinPrice = dto.MinPrice,
            MaxPrice = dto.MaxPrice,
            Category = string.IsNullOrWhiteSpace(dto.Category) ? null : dto.Category.Trim(),
            ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim(),
            IsAiGenerated = true,
            Status = dto.Status,
            StockQuantity = dto.StockQuantity,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.Products.Add(product);
        await _db.SaveChangesAsync();

        return Ok(product);
    }

    // GET: /api/products (kendi ürünlerin)
    [HttpGet]
    public async Task<IActionResult> GetMyProducts([FromQuery] ProductStatus? status = null)
    {
        var userId = GetUserId();

        var q = _db.Products.AsQueryable()
            .Where(p => p.UserId == userId);

        if (status is not null)
            q = q.Where(p => p.Status == status);

        var list = await q
            .OrderByDescending(p => p.CreatedAtUtc)
            .ToListAsync();

        return Ok(list);
    }

    // GET: /api/products/5
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var userId = GetUserId();

        var p = await _db.Products
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

        if (p is null) return NotFound();

        return Ok(p);
    }

    // POST: /api/products
    [HttpPost]
    public async Task<IActionResult> Create([FromForm] ProductCreateDto dto, IFormFile? file)
    {
        var userId = GetUserId();

        var product = new Product
        {
            UserId = userId,
            Title = dto.Title.Trim(),
            Description = dto.Description?.Trim(),
            MinPrice = dto.MinPrice,
            MaxPrice = dto.MaxPrice,
            Category = dto.Category?.Trim(),
            ImageUrl = dto.ImageUrl,
            IsAiGenerated = dto.IsAiGenerated,
            Status = dto.Status,              // 👈 artık client’tan geliyor
            StockQuantity = dto.StockQuantity,
            CreatedAtUtc = DateTime.UtcNow
        };

        if (file != null && file.Length > 0)
        {
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var ext = Path.GetExtension(file.FileName);
            var fileName = $"product_{Guid.NewGuid():N}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            product.ImageUrl = $"{baseUrl}/uploads/{fileName}";
        }

        _db.Products.Add(product);
        await _db.SaveChangesAsync();

        return Ok(product);
    }

    // PUT: /api/products/5
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromForm] ProductUpdateDto dto, IFormFile? file)
    {
        var userId = GetUserId();

        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == id);

        if (p is null) return NotFound();
        if (p.UserId != userId) return Forbid(); // 403 Forbidden

        p.Title = dto.Title.Trim();
        p.Description = dto.Description?.Trim();
        p.MinPrice = dto.MinPrice;
        p.MaxPrice = dto.MaxPrice;
        p.Category = dto.Category?.Trim();
        p.ImageUrl = dto.ImageUrl;
        p.IsAiGenerated = dto.IsAiGenerated;
        p.Status = dto.Status;
        p.StockQuantity = dto.StockQuantity;
        p.UpdatedAtUtc = DateTime.UtcNow;

        if (file != null && file.Length > 0)
        {
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var ext = Path.GetExtension(file.FileName);
            var fileName = $"product_{id}_{Guid.NewGuid():N}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            p.ImageUrl = $"{baseUrl}/uploads/{fileName}";
        }
        else
        {
            // Eğer dosya gönderilmediyse, eski ImageUrl'i koru veya dto.ImageUrl'den güncelle
            p.ImageUrl = dto.ImageUrl;
        }

        await _db.SaveChangesAsync();

        return Ok(p);
    }

    // DELETE: /api/products/5
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = GetUserId();
        var isAdmin = User.IsInRole("Admin");

        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == id);

        if (p is null) return NotFound();
        if (!isAdmin && p.UserId != userId) return Forbid(); // 403 Forbidden

        _db.Products.Remove(p);
        await _db.SaveChangesAsync();

        return NoContent();
    }

    // POST: /api/products/5/publish
    [HttpPost("{id:int}/publish")]
    public async Task<IActionResult> Publish(int id)
    {
        var userId = GetUserId();

        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == id);

        if (p is null) return NotFound();
        if (p.UserId != userId) return Forbid(); // 403 Forbidden

        p.Status = ProductStatus.Published;
        p.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(p);
    }

    private static string BuildSmartDescription(SmartProductCreateDto dto)
    {
        var title = dto.Title.Trim();
        var category = string.IsNullOrWhiteSpace(dto.Category) ? "Pet Ürünleri" : dto.Category.Trim();
        var petType = string.IsNullOrWhiteSpace(dto.PetType) ? "evcil dostlar" : dto.PetType.Trim();
        var highlights = string.IsNullOrWhiteSpace(dto.Highlights)
            ? "günlük kullanımda dengeli performans, pratik kullanım ve güvenli içerik yaklaşımı"
            : dto.Highlights.Trim();

        var priceText = dto.MinPrice.HasValue && dto.MaxPrice.HasValue
            ? $"Tahmini fiyat aralığı ₺{dto.MinPrice.Value:0.##} - ₺{dto.MaxPrice.Value:0.##} bandındadır."
            : "Tahmini fiyat aralığı pazar koşullarına göre değişebilir.";

        return $"{title}, {category} kategorisinde {petType} için önerilen bir üründür. " +
               $"Ürün öne çıkan özellikleri: {highlights}. " +
               "Düzenli kullanım senaryolarında pratiklik sağlamayı hedefler ve kullanıcı deneyimini destekler. " +
               "Ürünü kullanmadan önce ambalaj üzerindeki kullanım talimatları takip edilmelidir. " +
               $"{priceText}";
    }
}
