using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record CategoryUpdateDto(
    [Required, MaxLength(120)] string Name,
    [MaxLength(300)] string? Description
);
