using AkilliSatici.Api.Data;
using AkilliSatici.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AkilliSatici.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class SettingsController : ControllerBase
{
    private readonly AppDbContext _context;

    public SettingsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<StoreSettingsDto>> GetSettings()
    {
        var settings = await _context.StoreSettings.FirstOrDefaultAsync(s => s.Id == 1);
        if (settings == null)
        {
            settings = new StoreSettings { Id = 1 };
            _context.StoreSettings.Add(settings);
            await _context.SaveChangesAsync();
        }

        return Ok(new StoreSettingsDto
        {
            PopularCategories = JsonSerializer.Deserialize<List<string>>(settings.PopularCategoriesJson) ?? new List<string>(),
            PopularBrands = JsonSerializer.Deserialize<List<string>>(settings.PopularBrandsJson) ?? new List<string>()
        });
    }

    [HttpPut]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateSettings(StoreSettingsDto dto)
    {
        var settings = await _context.StoreSettings.FirstOrDefaultAsync(s => s.Id == 1);
        if (settings == null)
        {
            settings = new StoreSettings { Id = 1 };
            _context.StoreSettings.Add(settings);
        }

        settings.PopularCategoriesJson = JsonSerializer.Serialize(dto.PopularCategories);
        settings.PopularBrandsJson = JsonSerializer.Serialize(dto.PopularBrands);

        await _context.SaveChangesAsync();
        return NoContent();
    }
}

public class StoreSettingsDto
{
    public List<string> PopularCategories { get; set; } = new();
    public List<string> PopularBrands { get; set; } = new();
}
