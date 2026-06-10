using AkilliSatici.Api.Data;
using AkilliSatici.Api.Dtos;
using AkilliSatici.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly AppDbContext _db;

    public CategoriesController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll()
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .OrderBy(c => c.Name)
            .ToListAsync();

        return Ok(categories);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CategoryCreateDto dto)
    {
        var name = dto.Name.Trim();
        if (await _db.Categories.AnyAsync(c => c.Name == name))
            return BadRequest(new { message = "Bu kategori zaten mevcut." });

        var category = new Category
        {
            Name = name,
            Description = dto.Description?.Trim()
        };

        _db.Categories.Add(category);
        await _db.SaveChangesAsync();

        return Ok(category);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, CategoryUpdateDto dto)
    {
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == id);
        if (category is null) return NotFound();

        var name = dto.Name.Trim();
        var exists = await _db.Categories.AnyAsync(c => c.Id != id && c.Name == name);
        if (exists)
            return BadRequest(new { message = "Bu kategori adı kullanımda." });

        category.Name = name;
        category.Description = dto.Description?.Trim();

        await _db.SaveChangesAsync();
        return Ok(category);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == id);
        if (category is null) return NotFound();

        _db.Categories.Remove(category);
        await _db.SaveChangesAsync();

        return NoContent();
    }
}
