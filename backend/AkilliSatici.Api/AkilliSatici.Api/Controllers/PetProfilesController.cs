using AkilliSatici.Api.Data;
using AkilliSatici.Api.Dtos;
using AkilliSatici.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Sadece giriş yapmış kullanıcılar evcil hayvan profili yönetebilir
public class PetProfilesController : ControllerBase
{
    private readonly AppDbContext _db;

    public PetProfilesController(AppDbContext db)
    {
        _db = db;
    }

    private int GetUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(sub) || !int.TryParse(sub, out var userId))
            throw new UnauthorizedAccessException("Token içinde user id yok.");

        return userId;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyPets()
    {
        var userId = GetUserId();
        var pets = await _db.PetProfiles
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.CreatedAtUtc)
            .ToListAsync();

        return Ok(pets);
    }

    [HttpPost]
    public async Task<IActionResult> CreatePet([FromBody] PetProfileCreateDto dto)
    {
        var userId = GetUserId();

        var pet = new PetProfile
        {
            UserId = userId,
            Name = dto.Name.Trim(),
            Species = dto.Species.Trim(),
            Breed = dto.Breed?.Trim(),
            AgeYears = dto.AgeYears,
            AgeMonths = dto.AgeMonths,
            WeightKg = dto.WeightKg,
            IsNeutered = dto.IsNeutered,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.PetProfiles.Add(pet);
        await _db.SaveChangesAsync();

        return Ok(pet);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdatePet(int id, [FromBody] PetProfileUpdateDto dto)
    {
        var userId = GetUserId();
        var pet = await _db.PetProfiles.FirstOrDefaultAsync(p => p.Id == id);

        if (pet is null) return NotFound(new { message = "Evcil hayvan bulunamadı." });
        if (pet.UserId != userId) return Forbid(); // Sadece kendi hayvanını güncelleyebilir

        pet.Name = dto.Name.Trim();
        pet.Species = dto.Species.Trim();
        pet.Breed = dto.Breed?.Trim();
        pet.AgeYears = dto.AgeYears;
        pet.AgeMonths = dto.AgeMonths;
        pet.WeightKg = dto.WeightKg;
        pet.IsNeutered = dto.IsNeutered;

        await _db.SaveChangesAsync();

        return Ok(pet);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeletePet(int id)
    {
        var userId = GetUserId();
        var pet = await _db.PetProfiles.FirstOrDefaultAsync(p => p.Id == id);

        if (pet is null) return NotFound(new { message = "Evcil hayvan bulunamadı." });
        if (pet.UserId != userId) return Forbid(); // Sadece kendi hayvanını silebilir

        _db.PetProfiles.Remove(pet);
        await _db.SaveChangesAsync();

        return NoContent();
    }
}
