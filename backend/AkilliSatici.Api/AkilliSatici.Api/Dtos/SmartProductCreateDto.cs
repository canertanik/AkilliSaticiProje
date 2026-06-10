using System.ComponentModel.DataAnnotations;
using AkilliSatici.Api.Models;

namespace AkilliSatici.Api.Dtos;

public record SmartProductCreateDto(
    [Required, MaxLength(200)] string Title,
    string? Category,
    string? PetType,
    string? Highlights,
    string? GeneratedDescription,
    decimal? MinPrice,
    decimal? MaxPrice,
    string? ImageUrl,
    ProductStatus Status = ProductStatus.Published,
    int StockQuantity = 0
);
