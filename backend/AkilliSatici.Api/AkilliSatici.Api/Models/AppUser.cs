using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Models;

public class AppUser
{
    public int Id { get; set; }

    [Required, MaxLength(120)]
    public string FullName { get; set; } = "";

    [Required, MaxLength(120)]
    public string StoreName { get; set; } = "";

    [Required, MaxLength(200)]
    [EmailAddress]
    public string Email { get; set; } = "";

    [Required]
    public byte[] PasswordHash { get; set; } = Array.Empty<byte>();

    [Required]
    public byte[] PasswordSalt { get; set; } = Array.Empty<byte>();

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public List<Product> Products { get; set; } = new();

    public string? ResetCode { get; set; }

    public DateTime? ResetCodeExpires { get; set; }
}
