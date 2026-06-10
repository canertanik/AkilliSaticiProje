using System.ComponentModel.DataAnnotations;
using AkilliSatici.Api.Models;

namespace AkilliSatici.Api.Dtos;

public record ProductUpdateDto(
    [Required, MaxLength(200)] string Title,
    string? Description,
    decimal? MinPrice,
    decimal? MaxPrice,
    string? Category,
    string? ImageUrl,
    bool IsAiGenerated,
    ProductStatus Status,
    int StockQuantity
);
