using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record CategoryCreateDto(
    [Required, MaxLength(120)] string Name,
    [MaxLength(300)] string? Description
);
