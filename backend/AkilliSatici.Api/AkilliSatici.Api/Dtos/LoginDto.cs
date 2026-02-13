using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record LoginDto(
    [Required, EmailAddress] string Email,
    [Required] string Password
);
