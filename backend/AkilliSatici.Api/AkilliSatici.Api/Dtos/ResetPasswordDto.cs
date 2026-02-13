using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record ResetPasswordDto(
    [Required, EmailAddress] string Email,
    [Required] string Code,
    [Required] string NewPassword
);