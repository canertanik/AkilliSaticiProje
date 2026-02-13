using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record RegisterDto(
    [Required, MaxLength(120)] string FullName,
    [Required, MaxLength(120)] string StoreName,
    [Required, EmailAddress, MaxLength(200)] string Email,
    [Required, MinLength(6)] string Password
);
